using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using System.Text;
using Vortice.DirectWrite;
using Windows.Win32;
using Windows.Win32.Foundation;
using Windows.Win32.Graphics.Gdi;
using Windows.Win32.UI.Controls;
using Windows.Win32.UI.WindowsAndMessaging;

namespace Stripes;

// The window behind Screen Saver Settings' "Settings..." button: drawing options and a
// searchable checkbox list of locations. Mirrors OptionsSheet in macos/OptionsSheet.swift.
// A plain Win32 dialog, since WinForms and WPF don't support Native AOT. Its per-monitor DPI
// calls need Windows 10 1607, the oldest version .NET 10 supports.
[SupportedOSPlatform("windows10.0.14393")]
static unsafe class OptionsDialog
{
    // Control IDs, in tab order.
    const int IdStyle = 101, IdExit = 102, IdDuration = 103, IdDurationValue = 104, IdShowLabel = 105,
        IdFont = 106, IdSize = 107, IdSizeValue = 108, IdReset = 109, IdSearch = 110, IdList = 111,
        IdSelectedOnly = 113, IdStatus = 114, IdAbout = 115, IdCancel = 2, IdDone = 1;

    const int ResetButton = 1000;

    static StripesData data = null!;
    static SaverSettings saved = null!;
    static HWND dialog;
    static readonly Dictionary<int, HWND> controls = [];
    static readonly List<(HWND Hwnd, int Id, string Text)> labels = [];
    static readonly List<string> fontValues = [];
    static HashSet<string> chosen = [];
    static IReadOnlyList<Location> rows = [];
    static bool filling;
    static HFONT font, bold;
    static uint dpi = 96;

    public static int Show(nint owner, StripesData stripes)
    {
        data = stripes;
        saved = SettingsStore.Load();

        var icc = new INITCOMMONCONTROLSEX
        {
            dwSize = (uint)sizeof(INITCOMMONCONTROLSEX),
            dwICC = INITCOMMONCONTROLSEX_ICC.ICC_LISTVIEW_CLASSES | INITCOMMONCONTROLSEX_ICC.ICC_BAR_CLASSES
                | INITCOMMONCONTROLSEX_ICC.ICC_STANDARD_CLASSES,
        };
        PInvoke.InitCommonControlsEx(&icc);

        var template = Template("Stripes Options");
        fixed (byte* t = template)
        {
            var instance = (HINSTANCE)(nint)PInvoke.GetModuleHandle((PCWSTR)null).Value;
            return (int)PInvoke.DialogBoxIndirectParam(instance, (DLGTEMPLATE*)t, (HWND)owner, &DialogProc, 0);
        }
    }

    // An empty, resizable dialog; the controls are created and laid out in code.
    static byte[] Template(string title)
    {
        const uint style = 0x80000000 /* WS_POPUP */ | 0x00C00000 /* WS_CAPTION */ | 0x00080000 /* WS_SYSMENU */
            | 0x00040000 /* WS_THICKFRAME */ | 0x02000000 /* WS_CLIPCHILDREN */ | 0x80 /* DS_MODALFRAME */;
        using var ms = new MemoryStream();
        using var w = new BinaryWriter(ms, Encoding.Unicode);
        w.Write(style);
        w.Write(0u);          // extended style
        w.Write((ushort)0);   // no controls
        w.Write((short)0); w.Write((short)0); w.Write((short)300); w.Write((short)400);
        w.Write((ushort)0);   // no menu
        w.Write((ushort)0);   // default class
        foreach (var c in title) w.Write((ushort)c);
        w.Write((ushort)0);
        return ms.ToArray();
    }

    [UnmanagedCallersOnly(CallConvs = [typeof(CallConvStdcall)])]
    static nint DialogProc(HWND hwnd, uint msg, WPARAM wParam, LPARAM lParam)
    {
        try
        {
            return Handle(hwnd, msg, wParam, lParam);
        }
        catch (Exception e)
        {
            Log.Info($"options message {msg}: {e}");
            PInvoke.EndDialog(hwnd, IdCancel);
            return 1;
        }
    }

    static nint Handle(HWND hwnd, uint msg, WPARAM wParam, LPARAM lParam)
    {
        switch (msg)
        {
            case 0x0110:  // WM_INITDIALOG
                dialog = hwnd;
                dpi = PInvoke.GetDpiForWindow(hwnd);
                CreateControls();
                SetIcon();
                ShowSettings(saved);
                PlaceInitially();
                return 1;

            case 0x0005:  // WM_SIZE
                Layout();
                return 1;

            case 0x0024:  // WM_GETMINMAXINFO
            {
                var info = (MINMAXINFO*)lParam.Value;
                info->ptMinTrackSize = new System.Drawing.Point(S(420), S(550));
                return 1;
            }

            case 0x02E0:  // WM_DPICHANGED
            {
                dpi = (uint)(wParam.Value & 0xFFFF);
                CreateFonts();
                var r = (RECT*)lParam.Value;
                PInvoke.SetWindowPos(hwnd, HWND.Null, r->left, r->top, r->right - r->left, r->bottom - r->top,
                    SET_WINDOW_POS_FLAGS.SWP_NOZORDER | SET_WINDOW_POS_FLAGS.SWP_NOACTIVATE);
                Layout();
                return 1;
            }

            case 0x0114:  // WM_HSCROLL from a trackbar
                UpdateSliderValues();
                return 1;

            case 0x0111:  // WM_COMMAND
                return Command((int)(wParam.Value & 0xFFFF), (int)(wParam.Value >> 16));

            case 0x004E:  // WM_NOTIFY
                return Notify((NMHDR*)lParam.Value);

            case 0x0010:  // WM_CLOSE
                PInvoke.EndDialog(hwnd, IdCancel);
                return 1;

            case 0x0002:  // WM_DESTROY
                PInvoke.DeleteObject(font);
                PInvoke.DeleteObject(bold);
                controls.Clear();
                labels.Clear();
                return 0;
        }
        return 0;
    }

    static nint Command(int id, int code)
    {
        switch (id)
        {
            case IdShowLabel when code == 0:  // BN_CLICKED
                UpdateLabelEnabled();
                return 1;
            case IdSelectedOnly when code == 0:
                Refilter();
                return 1;
            case IdSearch when code == 0x0300:  // EN_CHANGE
                Refilter();
                return 1;
            case IdAbout when code == 0:
                ShowAbout();
                return 1;
            case IdReset when code == 0:
                ResetToDefaults();
                return 1;
            case IdDone:
                if (chosen.Count == 0) return 1;
                SettingsStore.Save(Collect());
                PInvoke.EndDialog(dialog, IdDone);
                return 1;
            case IdCancel:
                PInvoke.EndDialog(dialog, IdCancel);
                return 1;
        }
        return 0;
    }

    static nint Notify(NMHDR* hdr)
    {
        if ((int)hdr->idFrom == IdList && hdr->code == unchecked((uint)-101))  // LVN_ITEMCHANGED
        {
            var nm = (NMLISTVIEW*)hdr;
            const uint stateImage = 0xF000;
            if (filling || ((nm->uNewState ^ nm->uOldState) & stateImage) == 0 || nm->iItem < 0) return 0;
            var name = rows[nm->iItem].Name;
            if ((nm->uNewState & stateImage) == 0x2000) chosen.Add(name);
            else chosen.Remove(name);
            UpdateStatus();
            return 0;
        }
        return 0;
    }

    // --- Controls ---

    static void CreateControls()
    {
        Label("Build In:");
        var style = Create("COMBOBOX", IdStyle, 0x0003 /* CBS_DROPDOWNLIST */ | 0x00200000 /* WS_VSCROLL */);
        Label("Build Out:");
        var exit = Create("COMBOBOX", IdExit, 0x0003 | 0x00200000);
        foreach (var combo in new[] { style, exit })
        {
            foreach (var s in Enum.GetValues<DrawStyle>()) AddItem(combo, Title(s), (nint)s);
        }

        Label("Duration:");
        Slider(IdDuration, SaverSettings.MinDrawIn, SaverSettings.MaxDrawIn);
        Create("STATIC", IdDurationValue, 0);
        Create("BUTTON", IdShowLabel, 0x0003 /* BS_AUTOCHECKBOX */, "Show location and years");

        Label("Font:");
        var fontCombo = Create("COMBOBOX", IdFont, 0x0003 | 0x00200000);
        Send(fontCombo, 0x1701, 20);  // CB_SETMINVISIBLE
        fontValues.Clear();
        using (var writeFactory = DWrite.DWriteCreateFactory<IDWriteFactory>())
        {
            // The system fonts first, then every installed family by name, as on macOS.
            var mono = LabelPainter.ResolveFamily(writeFactory, SaverSettings.SystemMono);
            AddFont(fontCombo, mono, SaverSettings.SystemMono);
            AddFont(fontCombo, "Segoe UI", SaverSettings.System);
            foreach (var family in FontFamilies(writeFactory).Where(f => f != mono && f != "Segoe UI"))
            {
                AddFont(fontCombo, family, family);
            }
        }

        Label("Size:");
        Slider(IdSize, SaverSettings.MinLabelSize, SaverSettings.MaxLabelSize);
        Create("STATIC", IdSizeValue, 0);
        Create("BUTTON", IdReset, 0, "Reset to Defaults…");
        Create("BUTTON", IdAbout, 0, "About…");

        Create("STATIC", 0, 0x10 /* SS_ETCHEDHORZ */, tabStop: false);
        Label("Locations", bold: true);

        var search = Create("EDIT", IdSearch, 0x0080 /* ES_AUTOHSCROLL */, exStyle: 0x200 /* WS_EX_CLIENTEDGE */);
        fixed (char* cue = $"Search {data.Locations.Count} locations")
        {
            Send(search, 0x1501, 1, (nint)cue);  // EM_SETCUEBANNER, shown even while focused
        }

        var list = Create("SysListView32", IdList,
            0x0001 /* LVS_REPORT */ | 0x0004 /* LVS_SINGLESEL */ | 0x0008 /* LVS_SHOWSELALWAYS */ | 0x4000 /* LVS_NOCOLUMNHEADER */,
            exStyle: 0x200);
        const nint listStyles = 0x4 /* LVS_EX_CHECKBOXES */ | 0x20 /* LVS_EX_FULLROWSELECT */ | 0x10000 /* LVS_EX_DOUBLEBUFFER */;
        Send(list, 0x1036, (nuint)listStyles, listStyles);  // LVM_SETEXTENDEDLISTVIEWSTYLE
        var column = new LVCOLUMNW { mask = LVCOLUMNW_MASK.LVCF_WIDTH, cx = 100 };
        Send(list, 0x1061, 0, (nint)(&column));  // LVM_INSERTCOLUMNW

        Create("BUTTON", IdSelectedOnly, 0x0003, "Selected only");
        Create("STATIC", IdStatus, 0, tabStop: false);
        Create("BUTTON", IdCancel, 0, "Cancel");
        Create("BUTTON", IdDone, 0x0001 /* BS_DEFPUSHBUTTON */, "Done");

        CreateFonts();
    }

    static HWND Create(string className, int id, uint style, string text = "", uint exStyle = 0, bool tabStop = true)
    {
        var ws = 0x40000000u /* WS_CHILD */ | 0x10000000u /* WS_VISIBLE */ | style | (tabStop ? 0x00010000u /* WS_TABSTOP */ : 0);
        HWND hwnd;
        fixed (char* cls = className)
        fixed (char* txt = text)
        {
            hwnd = PInvoke.CreateWindowEx((WINDOW_EX_STYLE)exStyle, cls, txt, (WINDOW_STYLE)ws, 0, 0, 10, 10,
                dialog, (HMENU)(nint)id, HINSTANCE.Null, null);
        }
        if (id != 0) controls[id] = hwnd;
        else labels.Add((hwnd, 0, ""));
        return hwnd;
    }

    // Labels are kept in creation order; the bold one marks the Locations heading.
    static void Label(string text, bool bold = false)
    {
        var hwnd = Create("STATIC", 0, bold ? 0u : 0x2u /* SS_RIGHT */, text, tabStop: false);
        labels[^1] = (hwnd, bold ? 1 : 0, text);
    }

    static void Slider(int id, int min, int max)
    {
        var s = Create("msctls_trackbar32", id, 0x0010 /* TBS_NOTICKS */);
        Send(s, 0x0407, 0, min);  // TBM_SETRANGEMIN
        Send(s, 0x0408, 1, max);  // TBM_SETRANGEMAX
        Send(s, 0x0415, 0, 5);    // TBM_SETPAGESIZE
    }

    static void AddItem(HWND combo, string text, nint value)
    {
        nint index;
        fixed (char* t = text)
        {
            index = Send(combo, 0x0143, 0, (nint)t);  // CB_ADDSTRING
        }
        Send(combo, 0x0151, (nuint)index, value);  // CB_SETITEMDATA
    }

    static void AddFont(HWND combo, string title, string value)
    {
        fontValues.Add(value);
        AddItem(combo, title, fontValues.Count - 1);
    }

    static IEnumerable<string> FontFamilies(IDWriteFactory factory)
    {
        using var fonts = factory.GetSystemFontCollection(false);
        var names = new List<string>();
        for (var i = 0u; i < fonts.FontFamilyCount; i++)
        {
            using var family = fonts.GetFontFamily(i);
            using var localized = family.FamilyNames;
            if (!localized.FindLocaleName("en-us", out var index)) index = 0;
            var name = localized.GetString(index);
            if (name.Length > 0 && name[0] != '@') names.Add(name);
        }
        names.Sort(LogicalStringComparer.Instance);
        return names.Distinct();
    }

    static string Title(DrawStyle s) => s.ToString();

    static void SetIcon()
    {
        var instance = (HINSTANCE)(nint)PInvoke.GetModuleHandle((PCWSTR)null).Value;
        var icon = PInvoke.LoadIcon(instance, (PCWSTR)(char*)1);
        Send(dialog, 0x0080, 0, (nint)icon.Value);  // WM_SETICON, ICON_SMALL
        Send(dialog, 0x0080, 1, (nint)icon.Value);  // ICON_BIG
    }

    // --- State ---

    // Sets every control from the given settings, as OptionsSheet.show does.
    static void ShowSettings(SaverSettings s)
    {
        chosen = new HashSet<string>(s.Locations.Where(n => data.Find(n) is not null));
        SelectData(controls[IdStyle], (nint)s.Style);
        SelectData(controls[IdExit], (nint)s.ExitStyle);
        Send(controls[IdDuration], 0x0405, 1, (nint)Math.Round(s.DrawIn));  // TBM_SETPOS
        Send(controls[IdShowLabel], 0x00F1, s.ShowLabel ? 1u : 0u);        // BM_SETCHECK
        var fontIndex = fontValues.IndexOf(s.LabelFont);
        SelectData(controls[IdFont], Math.Max(0, fontIndex));
        Send(controls[IdSize], 0x0405, 1, s.LabelSize);
        UpdateSliderValues();
        UpdateLabelEnabled();
        SetText(controls[IdSearch], "");
        Send(controls[IdSelectedOnly], 0x00F1, 0);
        Refilter();
    }

    static SaverSettings Collect() => new()
    {
        Style = (DrawStyle)SelectedData(controls[IdStyle]),
        ExitStyle = (DrawStyle)SelectedData(controls[IdExit]),
        DrawIn = Send(controls[IdDuration], 0x0400),  // TBM_GETPOS
        ShowLabel = Send(controls[IdShowLabel], 0x00F0) == 1,  // BM_GETCHECK
        LabelFont = fontValues[(int)SelectedData(controls[IdFont])],
        LabelSize = (int)Send(controls[IdSize], 0x0400),
        Locations = data.Locations.Select(l => l.Name).Where(chosen.Contains).ToArray(),
    };

    // Resets the drawing options to the defaults after asking. The locations stay as they are,
    // and nothing is saved until Done.
    // The credit in full, who made the ports, and where to donate, with working links.
    static void ShowAbout()
    {
        var version = typeof(OptionsDialog).Assembly.GetName().Version?.ToString(3) ?? "";
        var instance = (HINSTANCE)(nint)PInvoke.GetModuleHandle((PCWSTR)null).Value;
        var icon = PInvoke.LoadIcon(instance, (PCWSTR)(char*)1);

        fixed (char* title = "About Stripes")
        fixed (char* main = "Stripes for Windows")
        fixed (char* content = $"Version {version}\n\n"
            + "Warming stripes by Ed Hawkins, University of Reading, under "
            + "<a href=\"https://creativecommons.org/licenses/by/4.0/\">CC BY 4.0</a>. "
            + "Colors sampled from <a href=\"https://showyourstripes.info\">showyourstripes.info</a> and animated.\n\n"
            + "Original idea and MacOS version by G.Karamanis. Windows version by C.T.Blunt.\n\n"
            + "The stripes are free to use. Show Your Stripes also accepts "
            + "<a href=\"https://showyourstripes.info/support\">donations</a> "
            + "for climate science and education at the University of Reading.")
        {
            var config = new TASKDIALOGCONFIG
            {
                cbSize = (uint)sizeof(TASKDIALOGCONFIG),
                hwndParent = dialog,
                dwFlags = TASKDIALOG_FLAGS.TDF_ENABLE_HYPERLINKS | TASKDIALOG_FLAGS.TDF_USE_HICON_MAIN
                    | TASKDIALOG_FLAGS.TDF_POSITION_RELATIVE_TO_WINDOW | TASKDIALOG_FLAGS.TDF_ALLOW_DIALOG_CANCELLATION,
                dwCommonButtons = TASKDIALOG_COMMON_BUTTON_FLAGS.TDCBF_CLOSE_BUTTON,
                pszWindowTitle = title,
                pszMainInstruction = main,
                pszContent = content,
                pfCallback = &AboutCallback,
            };
            config.Anonymous1.hMainIcon = icon;
            PInvoke.TaskDialogIndirect(&config, null, null, null);
        }
    }

    // Opens a link clicked in the About box in the default browser.
    [UnmanagedCallersOnly(CallConvs = [typeof(CallConvStdcall)])]
    static HRESULT AboutCallback(HWND hwnd, uint notification, WPARAM wParam, LPARAM lParam, nint data)
    {
        const uint hyperlinkClicked = 3;  // TDN_HYPERLINK_CLICKED
        if (notification == hyperlinkClicked)
        {
            fixed (char* open = "open")
            {
                PInvoke.ShellExecute(HWND.Null, open, (char*)lParam.Value, null, null, SHOW_WINDOW_CMD.SW_SHOWNORMAL);
            }
        }
        return (HRESULT)0;  // S_OK
    }

    static void ResetToDefaults()
    {
        fixed (char* title = "Stripes")
        fixed (char* main = "Reset the options to their defaults?")
        fixed (char* content = "Build in, build out, duration, label, font and size go back to the defaults. "
            + "The locations stay as they are. Nothing is saved until you click Done.")
        fixed (char* reset = "Reset")
        {
            var button = new TASKDIALOG_BUTTON { nButtonID = ResetButton, pszButtonText = reset };
            var config = new TASKDIALOGCONFIG
            {
                cbSize = (uint)sizeof(TASKDIALOGCONFIG),
                hwndParent = dialog,
                dwFlags = TASKDIALOG_FLAGS.TDF_POSITION_RELATIVE_TO_WINDOW,
                dwCommonButtons = TASKDIALOG_COMMON_BUTTON_FLAGS.TDCBF_CANCEL_BUTTON,
                pszWindowTitle = title,
                pszMainInstruction = main,
                pszContent = content,
                cButtons = 1,
                pButtons = &button,
                nDefaultButton = ResetButton,
            };
            int pressed;
            if (PInvoke.TaskDialogIndirect(&config, &pressed, null, null).Failed || pressed != ResetButton) return;
        }

        var keep = data.Locations.Select(l => l.Name).Where(chosen.Contains).ToArray();
        ShowSettings(new SaverSettings { Locations = keep });
    }

    static void Refilter()
    {
        var onlySelected = Send(controls[IdSelectedOnly], 0x00F0) == 1;
        rows = LocationSearch.Filter(data.Locations, GetText(controls[IdSearch]), onlySelected ? chosen : null);

        var list = controls[IdList];
        filling = true;
        Send(list, 0x000B, 0);  // WM_SETREDRAW off
        Send(list, 0x1009);     // LVM_DELETEALLITEMS
        for (var i = 0; i < rows.Count; i++)
        {
            fixed (char* text = rows[i].Name)
            {
                var item = new LVITEMW { mask = LIST_VIEW_ITEM_FLAGS.LVIF_TEXT, iItem = i, pszText = text };
                Send(list, 0x104D, 0, (nint)(&item));  // LVM_INSERTITEMW
            }
            if (chosen.Contains(rows[i].Name))
            {
                var check = new LVITEMW { stateMask = (LIST_VIEW_ITEM_STATE_FLAGS)0xF000, state = (LIST_VIEW_ITEM_STATE_FLAGS)0x2000 };
                Send(list, 0x102B, (nuint)i, (nint)(&check));  // LVM_SETITEMSTATE
            }
        }
        Send(list, 0x000B, 1);
        PInvoke.InvalidateRect(list, (RECT*)null, true);
        filling = false;
        if (rows.Count > 0) Send(list, 0x1013, 0, 0);  // LVM_ENSUREVISIBLE, the first row
        UpdateStatus();
    }

    static void UpdateStatus()
    {
        SetText(controls[IdStatus], $"{chosen.Count} selected");
        PInvoke.EnableWindow(controls[IdDone], chosen.Count > 0);
    }

    static void UpdateSliderValues()
    {
        SetText(controls[IdDurationValue], $"{Send(controls[IdDuration], 0x0400)} s");
        SetText(controls[IdSizeValue], $"{Send(controls[IdSize], 0x0400)} pt");
    }

    static void UpdateLabelEnabled()
    {
        var on = Send(controls[IdShowLabel], 0x00F0) == 1;
        foreach (var id in new[] { IdFont, IdSize, IdSizeValue }) PInvoke.EnableWindow(controls[id], on);
    }

    // --- Layout, in DIPs scaled to the dialog's DPI ---

    static int S(double dips) => (int)Math.Round(dips * dpi / 96);

    static void PlaceInitially()
    {
        // 460 × 560 points on macOS; Segoe UI 9 pt needs a little more room.
        var owner = PInvoke.GetParent(dialog);
        RECT area;
        if (owner != HWND.Null) PInvoke.GetWindowRect(owner, &area);
        else
        {
            var info = new MONITORINFO { cbSize = (uint)sizeof(MONITORINFO) };
            PInvoke.GetMonitorInfo(PInvoke.MonitorFromWindow(dialog, MONITOR_FROM_FLAGS.MONITOR_DEFAULTTONEAREST), &info);
            area = info.rcWork;
        }
        int w = S(480), h = S(590);
        var x = (area.left + area.right - w) / 2;
        var y = Math.Max(area.top, (area.top + area.bottom - h) / 2);
        PInvoke.SetWindowPos(dialog, HWND.Null, x, y, w, h, SET_WINDOW_POS_FLAGS.SWP_NOZORDER);
        Layout();

        // The list was scrolled while it was still tiny; show its top now it has its real size.
        Send(controls[IdList], 0x1013, 0, 0);  // LVM_ENSUREVISIBLE
    }

    static void Layout()
    {
        if (controls.Count == 0) return;
        RECT client;
        PInvoke.GetClientRect(dialog, &client);
        int width = client.right, height = client.bottom;

        int m = S(16), labelW = S(76), gap = S(8), cx = m + labelW + gap, ctrlW = S(230);
        int rowH = S(24), y = m;
        var labelIndex = 0;

        void PlaceLabel(int top)
        {
            var (hwnd, _, _) = labels[labelIndex++];
            Move(hwnd, m, top + S(3), labelW, S(20));
        }

        PlaceLabel(y); Move(controls[IdStyle], cx, y, ctrlW, S(300)); y += S(32);
        PlaceLabel(y); Move(controls[IdExit], cx, y, ctrlW, S(300)); y += S(32);
        PlaceLabel(y); Move(controls[IdDuration], cx - S(4), y, ctrlW + S(8), S(26));
        Move(controls[IdDurationValue], cx + ctrlW + gap, y + S(3), S(60), S(20)); y += S(34);
        Move(controls[IdShowLabel], cx, y, width - cx - m, S(20)); y += S(28);
        PlaceLabel(y); Move(controls[IdFont], cx, y, ctrlW, S(400)); y += S(32);
        PlaceLabel(y); Move(controls[IdSize], cx - S(4), y, ctrlW + S(8), S(26));
        Move(controls[IdSizeValue], cx + ctrlW + gap, y + S(3), S(60), S(20)); y += S(34);
        Move(controls[IdReset], cx, y, S(150), S(26));
        Move(controls[IdAbout], cx + S(150) + gap, y, S(100), S(26)); y += S(40);

        var (separator, _, _) = labels[labelIndex++];
        Move(separator, m, y, width - 2 * m, 2); y += S(12);
        var (heading, _, _) = labels[labelIndex++];
        Move(heading, m, y, width - 2 * m, S(20)); y += S(24);
        Move(controls[IdSearch], m, y, width - 2 * m, rowH); y += rowH + S(8);

        var buttonsY = height - m - S(26);
        Move(controls[IdList], m, y, width - 2 * m, Math.Max(S(60), buttonsY - S(12) - y));
        Send(controls[IdList], 0x101E, 0, -2);  // LVM_SETCOLUMNWIDTH, fill the width

        Move(controls[IdSelectedOnly], m, buttonsY + S(3), S(120), S(20));
        Move(controls[IdStatus], m + S(128), buttonsY + S(5), S(140), S(20));
        Move(controls[IdDone], width - m - S(88), buttonsY, S(88), S(26));
        Move(controls[IdCancel], width - m - 2 * S(88) - gap, buttonsY, S(88), S(26));
        PInvoke.InvalidateRect(dialog, (RECT*)null, true);
    }

    static void Move(HWND hwnd, int x, int y, int w, int h) => PInvoke.MoveWindow(hwnd, x, y, w, h, true);

    static void CreateFonts()
    {
        var metrics = new NONCLIENTMETRICSW { cbSize = (uint)sizeof(NONCLIENTMETRICSW) };
        PInvoke.SystemParametersInfoForDpi(0x0029 /* SPI_GETNONCLIENTMETRICS */, metrics.cbSize, &metrics, 0, dpi);
        var message = metrics.lfMessageFont;
        var heading = message;
        heading.lfWeight = 700;

        var oldFont = font;
        var oldBold = bold;
        font = PInvoke.CreateFontIndirect(&message);
        bold = PInvoke.CreateFontIndirect(&heading);
        foreach (var hwnd in controls.Values) Send(hwnd, 0x0030, (nuint)(nint)font.Value, 1);  // WM_SETFONT
        foreach (var (hwnd, isBold, _) in labels) Send(hwnd, 0x0030, (nuint)(nint)(isBold == 1 ? bold : font).Value, 1);
        if (!oldFont.IsNull) PInvoke.DeleteObject(oldFont);
        if (!oldBold.IsNull) PInvoke.DeleteObject(oldBold);
    }

    // --- Helpers ---

    static nint Send(HWND hwnd, uint msg, nuint wParam = 0, nint lParam = 0) =>
        PInvoke.SendMessage(hwnd, msg, wParam, lParam).Value;

    static void SelectData(HWND combo, nint value)
    {
        var count = (int)Send(combo, 0x0146);  // CB_GETCOUNT
        for (var i = 0; i < count; i++)
        {
            if (Send(combo, 0x0150, (nuint)i) == value)  // CB_GETITEMDATA
            {
                Send(combo, 0x014E, (nuint)i);  // CB_SETCURSEL
                return;
            }
        }
        Send(combo, 0x014E, 0);
    }

    static nint SelectedData(HWND combo)
    {
        var index = Send(combo, 0x0147);  // CB_GETCURSEL
        return index < 0 ? 0 : Send(combo, 0x0150, (nuint)index);
    }

    static void SetText(HWND hwnd, string text)
    {
        fixed (char* t = text) PInvoke.SetWindowText(hwnd, t);
    }

    static string GetText(HWND hwnd)
    {
        var length = PInvoke.GetWindowTextLength(hwnd);
        if (length == 0) return "";
        var buffer = new char[length + 1];
        fixed (char* b = buffer)
        {
            var n = PInvoke.GetWindowText(hwnd, b, buffer.Length);
            return new string(b, 0, n);
        }
    }
}
