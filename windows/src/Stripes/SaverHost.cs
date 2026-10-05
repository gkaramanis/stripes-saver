using System.Diagnostics;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using Vortice.Direct2D1;
using Windows.Win32;
using Windows.Win32.Foundation;
using Windows.Win32.Graphics.Gdi;
using Windows.Win32.UI.WindowsAndMessaging;

namespace Stripes;

// The Windows side of the screen saver: one full-screen window per monitor for /s, or one
// child of the Screen Saver Settings preview for /p, redrawn at 30 fps until it should end.
static unsafe class SaverHost
{
    const string ClassName = "StripesScreenSaver";
    const double FrameInterval = 1.0 / 30;

    // Pixels the mouse may drift before /s ends, so a bumped desk doesn't stop the saver.
    const int MouseTolerance = 5;

    static readonly Dictionary<nint, SaverWindow> windows = [];
    static readonly List<RECT> monitors = [];
    static SaverMode mode;
    static HWND previewParent;
    static System.Drawing.Point? mouseStart;

    public static int Run(ScreenSaverArgs args, StripesData data, SaverSettings settings)
    {
        mode = args.Mode;
        Log.Info($"start {args.Mode} window={args.Window}");
        var instance = (HINSTANCE)(nint)PInvoke.GetModuleHandle((PCWSTR)null).Value;
        RegisterWindowClass(instance);

        using var factory = D2D1.D2D1CreateFactory<ID2D1Factory>(FactoryType.SingleThreaded);
        var locations = data.Resolve(settings.Locations);
        var now = Now();

        if (mode == SaverMode.Preview)
        {
            previewParent = (HWND)args.Window;
            RECT r;
            if (!PInvoke.GetClientRect(previewParent, &r)) return 1;
            Create(factory, instance, previewParent, r, locations, settings, now);
        }
        else
        {
            // Like macOS, each monitor runs its own timeline: same locations, its own random orders.
            PInvoke.EnumDisplayMonitors(HDC.Null, (RECT*)null, &OnMonitor, 0);
            foreach (var r in monitors) Create(factory, instance, HWND.Null, r, locations, settings, now);
        }
        Log.Info($"{windows.Count} window(s)");
        if (windows.Count == 0) return 1;

        // 1 ms timer resolution keeps the 30 fps waits even, instead of 15.6 ms steps.
        PInvoke.timeBeginPeriod(1);
        try
        {
            return Loop();
        }
        finally
        {
            PInvoke.timeEndPeriod(1);
            foreach (var w in windows.Values) w.Dispose();
            windows.Clear();
        }
    }

    // Placeholder until the options dialog arrives (milestone M4).
    public static int ShowOptions(nint owner)
    {
        fixed (char* text = "Stripes has no options yet. They arrive in a later build.")
        fixed (char* caption = "Stripes")
        {
            PInvoke.MessageBox((HWND)owner, text, caption, MESSAGEBOX_STYLE.MB_OK | MESSAGEBOX_STYLE.MB_ICONINFORMATION);
        }
        return 0;
    }

    static void RegisterWindowClass(HINSTANCE instance)
    {
        fixed (char* name = ClassName)
        {
            var wc = new WNDCLASSEXW
            {
                cbSize = (uint)sizeof(WNDCLASSEXW),
                lpfnWndProc = &WndProc,
                hInstance = instance,
                lpszClassName = name,
            };
            PInvoke.RegisterClassEx(&wc);
        }
    }

    static void Create(ID2D1Factory factory, HINSTANCE instance, HWND parent, RECT r,
        IReadOnlyList<Location> locations, SaverSettings settings, double now)
    {
        var preview = parent != HWND.Null;
        var style = preview
            ? WINDOW_STYLE.WS_CHILD | WINDOW_STYLE.WS_VISIBLE
            : WINDOW_STYLE.WS_POPUP | WINDOW_STYLE.WS_VISIBLE;
        var exStyle = preview ? 0 : WINDOW_EX_STYLE.WS_EX_TOPMOST | WINDOW_EX_STYLE.WS_EX_TOOLWINDOW;
        int width = r.right - r.left, height = r.bottom - r.top;

        HWND hwnd;
        fixed (char* name = ClassName)
        {
            hwnd = PInvoke.CreateWindowEx(exStyle, name, name, style,
                preview ? 0 : r.left, preview ? 0 : r.top, width, height,
                parent, HMENU.Null, instance, null);
        }
        Log.Info($"window {(nint)hwnd} {width}x{height} at {r.left},{r.top} preview={preview}");
        if (hwnd == HWND.Null) return;

        var timeline = new Timeline(locations, settings, new Random(), now);
        windows[hwnd] = new SaverWindow(new StripesRenderer(factory, hwnd, width, height), timeline, width, height);
    }

    static int Loop()
    {
        var next = Now();
        MSG msg;
        while (true)
        {
            while (PInvoke.PeekMessage(&msg, HWND.Null, 0, 0, PEEK_MESSAGE_REMOVE_TYPE.PM_REMOVE))
            {
                if (msg.message == PInvoke.WM_QUIT)
                {
                    Log.Info($"quit {msg.wParam.Value}");
                    return (int)msg.wParam.Value;
                }
                PInvoke.TranslateMessage(&msg);
                PInvoke.DispatchMessage(&msg);
            }

            // The preview's parent can vanish without our child seeing WM_DESTROY first.
            if (mode == SaverMode.Preview && !PInvoke.IsWindow(previewParent))
            {
                Log.Info("preview parent gone");
                PInvoke.PostQuitMessage(0);
                continue;
            }

            var now = Now();
            if (now >= next)
            {
                foreach (var w in windows.Values) w.Tick(now);
                next += FrameInterval;
                if (next < now) next = now + FrameInterval;
            }

            var wait = (uint)Math.Max(0, Math.Ceiling((next - Now()) * 1000));
            PInvoke.MsgWaitForMultipleObjectsEx(0, null, wait, QUEUE_STATUS_FLAGS.QS_ALLINPUT,
                MSG_WAIT_FOR_MULTIPLE_OBJECTS_EX_FLAGS.MWMO_INPUTAVAILABLE);
        }
    }

    [UnmanagedCallersOnly(CallConvs = [typeof(CallConvStdcall)])]
    static LRESULT WndProc(HWND hwnd, uint msg, WPARAM wParam, LPARAM lParam)
    {
        // An exception must not unwind into Windows; end the saver instead.
        try
        {
            return Handle(hwnd, msg, wParam, lParam);
        }
        catch (Exception e)
        {
            Log.Info($"message {msg}: {e}");
            PInvoke.PostQuitMessage(1);
            return (LRESULT)0;
        }
    }

    static LRESULT Handle(HWND hwnd, uint msg, WPARAM wParam, LPARAM lParam)
    {
        switch (msg)
        {
            case PInvoke.WM_PAINT:
            {
                PAINTSTRUCT ps;
                PInvoke.BeginPaint(hwnd, &ps);
                if (windows.TryGetValue(hwnd, out var w)) w.Paint(Now());
                PInvoke.EndPaint(hwnd, &ps);
                return (LRESULT)0;
            }
            case PInvoke.WM_ERASEBKGND:
                return (LRESULT)1;
            case PInvoke.WM_DESTROY:
                Log.Info($"destroy {(nint)hwnd}");
                if (windows.Remove(hwnd, out var gone)) gone.Dispose();
                if (mode == SaverMode.Preview || windows.Count == 0) PInvoke.PostQuitMessage(0);
                return (LRESULT)0;
            case PInvoke.WM_SYSCOMMAND when (wParam.Value & 0xFFF0) == PInvoke.SC_SCREENSAVE:
                return (LRESULT)0;
        }

        if (mode == SaverMode.Show)
        {
            switch (msg)
            {
                case PInvoke.WM_SETCURSOR:
                    PInvoke.SetCursor(HCURSOR.Null);
                    return (LRESULT)1;
                case PInvoke.WM_KEYDOWN:
                case PInvoke.WM_SYSKEYDOWN:
                case PInvoke.WM_LBUTTONDOWN:
                case PInvoke.WM_RBUTTONDOWN:
                case PInvoke.WM_MBUTTONDOWN:
                case PInvoke.WM_XBUTTONDOWN:
                case PInvoke.WM_MOUSEWHEEL:
                case PInvoke.WM_DISPLAYCHANGE:
                    PInvoke.PostQuitMessage(0);
                    return (LRESULT)0;
                case PInvoke.WM_ACTIVATEAPP when wParam.Value == 0:
                    PInvoke.PostQuitMessage(0);
                    break;
                case PInvoke.WM_MOUSEMOVE:
                {
                    // Windows sends a move when the windows appear, so compare with the first position.
                    System.Drawing.Point p;
                    PInvoke.GetCursorPos(&p);
                    if (mouseStart is not { } start) mouseStart = p;
                    else if (Math.Abs(p.X - start.X) > MouseTolerance || Math.Abs(p.Y - start.Y) > MouseTolerance)
                        PInvoke.PostQuitMessage(0);
                    return (LRESULT)0;
                }
            }
        }

        return PInvoke.DefWindowProc(hwnd, msg, wParam, lParam);
    }

    [UnmanagedCallersOnly(CallConvs = [typeof(CallConvStdcall)])]
    static BOOL OnMonitor(HMONITOR monitor, HDC dc, RECT* bounds, LPARAM data)
    {
        monitors.Add(*bounds);
        return true;
    }

    static double Now() => Stopwatch.GetTimestamp() / (double)Stopwatch.Frequency;
}

// One monitor's (or the preview's) window: its own timeline, draw list and renderer.
sealed class SaverWindow(StripesRenderer renderer, Timeline timeline, int width, int height) : IDisposable
{
    readonly DrawList list = new();

    public void Tick(double now)
    {
        if (timeline.Tick(now) is { } frame) Draw(frame);
    }

    public void Paint(double now) => Draw(timeline.StateAt(now));

    void Draw(FrameState frame)
    {
        Painter.Frame(list, frame, width, height);
        renderer.Render(list);
    }

    public void Dispose() => renderer.Dispose();
}
