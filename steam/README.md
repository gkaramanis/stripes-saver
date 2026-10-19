# Stripes for Steam

The warming stripes as a Steam screensaver, for the Steam Deck and Big Picture mode. It draws the same ten styles as the macOS version, from the same data, and follows [SPEC.md](../SPEC.md).

Steam added custom screensavers in the client update of 13 October 2026. Each one is a folder with an `index.html`, under `~/.steam/root/config/uioverrides/screensavers/`. Steam shows this one as "stripes (User Created)".

The folder name must be lowercase. Steam turns it into a hostname, which the browser lowercases, and then looks the folder up by that name. On SteamOS, file names are case-sensitive, so a folder called `Stripes` fails with "Error Code: -105".

## Install on a Steam Deck

1. Switch to Desktop Mode.
2. Download [Stripes-steam.zip](https://github.com/gkaramanis/stripes-saver/releases/download/steam-v1.0/Stripes-steam.zip) (95 KB) and extract it, so you have a `stripes` folder.
3. Move that folder into `~/.steam/root/config/uioverrides/screensavers/`. Create `uioverrides` and `screensavers` if they don't exist. In Dolphin, press Ctrl+H to show hidden folders such as `.steam`.
4. Switch back to Gaming Mode and choose stripes under Settings → Customization → Screensaver. Preview shows it right away.

From a Mac or Linux machine with ssh access to the Deck, `steam/build.sh deck <host>` builds the folder and copies it over. An existing `config.js` on the Deck is kept.

## Install on Windows (untested)

Big Picture on Windows should run it too, but it hasn't been tested there. Extract the zip and move the `stripes` folder into `config\uioverrides\screensavers\` inside the Steam install folder, usually `C:\Program Files (x86)\Steam`. Then open Big Picture and choose stripes under Settings → Customization → Screensaver.

## Options

Steam has no options screen for custom screensavers, so the options live in `stripes/config.js`. Edit it with any text editor, then pick the screensaver again or restart Steam. The options and defaults match the macOS version: build in Sweep, build out Fade, 14 seconds each, the label on, and Global.

The label uses SF Mono where it's installed. SteamOS doesn't have it, so the Deck falls back to DejaVu Sans Mono or the system monospace font. `labelSize` scales with the screen height, so the label keeps its proportions when the Deck is docked to a larger display.

## Building

```sh
steam/build.sh                # build steam/build/stripes and steam/build/Stripes-steam.zip
steam/build.sh deck <host>    # build, then copy to the Deck over ssh
```

The build copies `src/` and wraps `data/stripes.json` as `stripes.js`, so the page loads its data as a script and needs no fetch.

Open `build/stripes/index.html` in a browser to preview it. Query parameters override `config.js`. For example, `index.html?style=mosaic&drawIn=5&t=3` freezes Mosaic three seconds into a five-second build, and `locations=Global|Sweden` picks locations. Frozen frames match `macos/tools/render` to within a pixel at stripe edges.

## Data and credit

Warming stripes by [Ed Hawkins](https://edhawkins.org/), University of Reading, under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Colors sampled from [showyourstripes.info](https://showyourstripes.info) and animated. The credit is also in `config.js`, which ships with the screensaver.
