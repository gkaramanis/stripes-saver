# Stripes for Windows (c) C.T.Blunt

The Windows port of the original MacOS Stripes screensaver. It draws the warming stripes for any of the 1,069 locations in `data/stripes.json`, with the same nine styles and options as the macOS version.

## Install

Stripes runs on Windows 10 (version 1607 or later) and Windows 11, on Intel/AMD (x64) and Arm64 PCs. It is a single file, `Stripes.scr`, and needs nothing else installed.

1. **Download** `Stripes.scr` from the [Releases](https://github.com/gkaramanis/stripes-saver/releases) page: pick the latest `windows-v…` release, then the **x64** file for most PCs or **Arm64** for Snapdragon-based PCs. If you're not sure which you have, see Settings → System → About → **System type**.
2. **Unblock it.** The file isn't code-signed, so Windows treats a downloaded copy with caution. Right-click `Stripes.scr` → **Properties**, tick **Unblock** at the bottom of the General tab (if it's there), and click **OK**.
3. **Put it somewhere permanent**, such as a `Stripes` folder in your Documents. Windows runs the screensaver from wherever the file is, so don't leave it in Downloads if you tidy that folder.
4. **Install it.** Right-click `Stripes.scr` and choose **Install**. On Windows 11, choose **Show more options** first. This makes Stripes your screensaver and opens the Screen Saver Settings window.

If Windows shows *"Windows protected your PC"*, click **More info** → **Run anyway**. This appears because the file isn't signed.

## Turn it on and choose your options

Open Screen Saver Settings. Step 4 opens it for you; otherwise go to Settings → Personalization → Lock screen → **Screen saver**.

- Choose **Stripes** from the list, set **Wait** to how many minutes of inactivity before it starts, and click **OK**.
- **Preview** shows it full screen; move the mouse or press a key to stop it.
- **Settings…** opens the Stripes options:
  - **Build In and Build Out:** how the stripes appear and disappear. Random uses a different style each time.
  - **Duration:** how long each build takes.
  - **Show location and years:** turns the caption on or off, with its font and size.
  - **Locations:** tick as many as you like; use the search box to find places such as your town or country. Stripes plays them in turn, starting with Global.
  - **About…** has the credits and links.

## Uninstall

In Screen Saver Settings, choose **(None)** and click **OK**, then delete `Stripes.scr`. Its options are kept in the registry under `HKEY_CURRENT_USER\Software\Stripes`; delete that key too if you want to remove every trace.

## Building from source

See [DESIGN.md](DESIGN.md) for the design, prerequisites and plan, and [SPEC.md](../SPEC.md) for the behaviour it follows.

```powershell
dotnet test                                                     # from windows/
dotnet publish src\Stripes -c Release -r win-x64 -o publish\win-x64
```

The publish step produces `publish\win-x64\Stripes.scr`. Native AOT needs the MSVC build tools; see DESIGN.md → Building.

Report problems with the Windows version in [GitHub issues](https://github.com/gkaramanis/stripes-saver/issues).
