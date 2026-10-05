# Stripes for Windows

The Windows port of the Stripes screensaver. It draws the warming stripes for any of the 1,069 locations in `data/stripes.json`, with the same nine styles and options as the macOS version.

**Work in progress.** It runs full screen and in the Screen Saver Settings preview, with all nine styles and the location-and-years label. The options dialog is still to come; until then it uses the default options. See [DESIGN.md](DESIGN.md) for the design, prerequisites and plan, and [SPEC.md](../SPEC.md) for the behaviour it follows.

```powershell
dotnet test                                                     # from windows/
dotnet publish src\Stripes -c Release -r win-x64 -o publish\win-x64
```

The publish step produces `publish\win-x64\Stripes.scr`. Native AOT needs the MSVC build tools; see DESIGN.md → Building.

Report problems with the Windows version in [GitHub issues](https://github.com/gkaramanis/stripes-saver/issues).
