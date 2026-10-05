# Stripes for Windows: design

This describes how the Windows port is built. **What it draws, and when, is defined by [SPEC.md](../SPEC.md)**, with the Swift code in `macos/` as the final reference. This file covers only what is specific to Windows, so the two can't drift apart.

## Goals

- Behave exactly like the macOS saver: the same nine styles, options, defaults, timing, label and data.
- A single small native `Stripes.scr` with no runtime to install, for x64 and Arm64 Windows 10/11.
- Fully offline. The data is embedded at build time.
- Follow the Windows screen saver conventions: full screen on every monitor, the small preview in Screen Saver Settings, and the options dialog.

## Stack

| Part | Choice | Why |
|---|---|---|
| Language | C# on **.NET 10 (LTS)** | Memory-safe and approachable for contributors |
| Publish | **Native AOT** → one native exe, copied to `Stripes.scr` | No .NET runtime needed, about 2.4 MB, fast start |
| Win32 | [CsWin32](https://github.com/microsoft/CsWin32) source-generated P/Invoke | AOT-safe access to windows, monitors, DPI, registry, dialogs |
| Drawing | **Direct2D** on a Direct3D 11 device ([Vortice.Windows](https://github.com/amerkoleci/Vortice.Windows)) | Antialiased quads (Blinds), clipping (Iris), DirectWrite and shadow for the label |
| Data | `data/stripes.json`, embedded as a resource and read with source-generated `System.Text.Json` | Shared with macOS. No reflection under AOT |
| Options UI | Plain Win32 dialog | WinForms and WPF don't support Native AOT |

## Layout

```
windows/
  Stripes.slnx
  Directory.Build.props        shared build settings (net10.0-windows, warnings as errors, version)
  src/Stripes.Core/            platform-neutral logic: data, timeline, styles (unit-tested)
  src/Stripes/                 the .scr: screen saver host, Direct2D renderer, options dialog
  tests/Stripes.Core.Tests/    xUnit tests for Stripes.Core
```

`Stripes.Core` has no window or GPU code, so everything that decides *what* to draw can be tested without a display. `Stripes` only turns the draw lists into pixels and handles Windows.

## Screen saver contract

`Stripes.scr` is an ordinary exe that Windows launches with:

| Arguments | Mode |
|---|---|
| `/s` | Full screen on every monitor. Exit on a key press, a click, or mouse movement past a small threshold (ignore the first move messages, which Windows sends at start-up) |
| `/p <HWND>` | Draw inside the preview window as a child. Exit when the parent is destroyed |
| `/c` or `/c:<HWND>`, or no arguments | Show the options dialog, owned by the given window |

Arguments are case-insensitive and accept `-` or `/`, and `:` or a space before the value. The process is per-monitor DPI aware (v2), hides the cursor in `/s`, and stops drawing while the display is off or the session is locked.

**Name.** Windows shows the string resource with ID 1, falling back to the file name. Both say "Stripes". A VERSIONINFO resource carries the product name and the credit from the macOS `Info.plist`.

## Data

`StripesData` reads the embedded `data/stripes.json` (format in [SPEC.md → Data](../SPEC.md#data)):

- The palette is read from the file. Its order is not fixed, so no colour is ever hard-coded by index. It holds the 18 official colours, plus grey `7f7f7f` for years without data.
- Display names follow SPEC.md. Global comes first, then the rest are sorted with `StrCmpLogicalW`, Explorer's order, which is the closest match to Finder's `localizedStandardCompare`.
- `Resolve(names)` turns the saved Locations option into the play list: the names that still exist, in display order, or Global if none do.
- Loading fails loudly on a bad colour, an unknown key, a duplicate name or a missing Global, so a broken data refresh can't ship.

## Rendering

Each style is a **line-for-line port of its formulas in SPEC.md**, computed on the CPU into a draw list of rectangles, quads and clips. Direct2D then draws the list. Porting the formulas directly makes each style easy to check against the Swift code. The load is small: at most about 290 stripes, or about 3,500 Mosaic tiles, at 30 fps.

- **Stripe edges:** `round(i·W/n)`. Mosaic tile rows: `round(row·H/12)`. Axis-aligned stripes are drawn without antialiasing (no seams). Blinds quads are antialiased, with the 0.5 px right-edge overlap.
- **Coordinates:** SPEC.md uses AppKit coordinates (origin bottom-left, y up). Direct2D's y points down, so one helper flips the vertical positions for Rise, Drop, Mosaic rows and the label corners.
- **Timing:** 30 fps, with no redraws during the 15-second hold. Frames are paced by the swap chain or a timer, never a busy loop.
- **Monitors:** as on macOS, each monitor runs its own independent timeline. All start at the first chosen location, and each has its own Random bags, Scatter/Mosaic orders and label corner.
- **Label fonts:** `systemMono` → Cascadia Mono (falling back to Consolas), and `system` → Segoe UI. Any other value is an installed family name.

## Options

The options use the same keys, defaults and ranges as macOS (SPEC.md → Options). They are stored in `HKCU\Software\Stripes`:

| Key | Type | Default |
|---|---|---|
| `style` | REG_SZ | `sweep` |
| `exitStyle` | REG_SZ | `fade` |
| `drawIn` | REG_DWORD, seconds 5–60 | 14 |
| `showLabel` | REG_DWORD 0/1 | 1 |
| `labelFont` | REG_SZ | `systemMono` |
| `labelSize` | REG_DWORD, points 12–72 | 24 |
| `locations` | REG_MULTI_SZ | `Global` |

The dialog matches the macOS sheet:
- Searching matches location and region names, ignoring case and diacritics (`CompareStringEx` with `NORM_IGNORECASE | NORM_IGNORENONSPACE`).
- A "selected only" filter, plus a count of selected locations. Done stays disabled while none are ticked.
- `Reset to Defaults…` asks first and leaves Locations alone.
- It shows the required credit, with both links.

## Testing

- **Unit tests** (`tests/`): data loading and validation, names, ordering, and the fallback to Global. As styles land, tests cover their helpers (`smooth`, `waveAt`, `dropFall`, the Blinds projection) and the draw lists at chosen progress values.
- **Against macOS:** frames from `macos/tools/render` (Global, label off) are the reference. A matching Windows render tool will compare frames per pixel with a small tolerance for antialiasing and font differences. *This needs reference frames committed from a Mac.*
- **By hand:** `/s`, `/p` and `/c`, no arguments, multiple monitors, mixed DPI, plugging a monitor in or out, Remote Desktop, lock/unlock and display power-off.

## Building

Prerequisites:
- The **.NET 10 SDK**.
- **Visual Studio 2022 or later Build Tools** with "Desktop development with C++", including the Arm64 tools. Native AOT needs the MSVC linker.

```powershell
winget install Microsoft.DotNet.SDK.10
winget install Microsoft.VisualStudio.2022.BuildTools --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --add Microsoft.VisualStudio.Component.VC.Tools.ARM64"
```

If publishing fails with `'vswhere.exe' is not recognized … link.exe … exited with code 3`, add the Visual Studio Installer folder to your user PATH and open a new terminal:

```powershell
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path","User") + ";${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer", "User")
```

Then, from `windows/`:

```powershell
dotnet test
dotnet publish src\Stripes -c Release -r win-x64   -o publish\win-x64     # publish\win-x64\Stripes.scr
dotnet publish src\Stripes -c Release -r win-arm64 -o publish\win-arm64
```

Releases are tagged `windows-vX.Y`.

## Plan

| Milestone | Scope | Status |
|---|---|---|
| M1 | Solution, data reader, names, ordering, tests | Done |
| M2 | `/s` `/p` `/c` host, monitor windows, Direct2D drawing of the finished stripes, 30 fps timeline. Check Vortice under AOT, the preview child window, resources (string table, version info, icon) | |
| M3 | The nine styles (Sweep and Fade first) plus Random, and the label | |
| M4 | Options dialog and registry storage | |
| M5 | Reference-frame comparison, CI (x64 + Arm64), `windows-v1.0` release | |

## Open questions

- Reference frames from `macos/tools/render` committed to the repo, so the port can be checked without a Mac.
- The LICENSE copyright line for the Windows code (being agreed). The LICENSE's data path should read `data/stripes.json`.
