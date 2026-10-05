# Stripes behaviour spec

This describes what Stripes.saver 1.0 (build 9) draws and how, for anyone porting it to another platform. The Swift source is the reference; where this file and the code disagree, the code wins. File and line references point at `StripesView.swift` unless noted.

Coordinates follow AppKit, with the origin at the bottom-left and y pointing up. A port with y pointing down has to flip the vertical positions in Rise, Drop and the label.

## Options

| Option | Key | Type | Default | Range or values |
|---|---|---|---|---|
| Build In | `style` | style name | `sweep` | `sweep`, `rise`, `scatter`, `fade`, `drop`, `flip`, `blinds`, `iris`, `mosaic`, `random` |
| Build Out | `exitStyle` | style name | `fade` | same as Build In |
| Duration | `drawIn` | seconds | 14 | 5 to 60, whole seconds |
| Show location and years | `showLabel` | bool | true | |
| Font | `labelFont` | family name | `systemMono` | `systemMono` (SF Mono), `system` (SF Pro), or any installed family |
| Size | `labelSize` | points | 24 | 12 to 72, whole points |
| Locations | `locations` | list of names | `["Global"]` | any names from the data, at least one |

- Duration applies to the build in, and again to the build out.
- The label is drawn in medium weight. If the saved family isn't installed, it falls back to SF Mono. On Windows, Cascadia Mono or Consolas are the closest stand-ins for SF Mono, and Segoe UI for SF Pro.
- The options dialog has a search field that matches location names and region names, ignoring case and diacritics. It also has a "selected only" filter and a count of selected locations, and Done stays disabled while none are ticked.
- `Reset to Defaults…` asks first. It resets every option except Locations, and nothing is saved until Done.
- The dialog shows this credit, with both links: "Warming stripes by Ed Hawkins, University of Reading, under CC BY 4.0. Colors sampled from showyourstripes.info and animated." A port must keep a credit like this, because the data is CC BY 4.0.

## Data

`Resources/stripes.json` is built by `sample.py`. It samples one colour per year from every official image on [showyourstripes.info](https://showyourstripes.info).

```json
{
  "palette": ["08519c", "fcbba1", "…"],
  "locations": [
    {"region": "Africa", "country": "Algeria", "place": "", "firstYear": 1896, "source": "BK", "stripes": "0123245646…"}
  ]
}
```

- `palette` holds 19 sRGB colours as hex. The last, `7f7f7f`, is grey. It appears in 10 locations, most likely for years the official images leave without data.
- `stripes` has one character per year, starting at `firstYear`. Each character indexes `palette` through `0–9a–zA–Z`, so `0` is palette[0] and `i` is palette[18].
- `source` is the dataset code from the image's file name. The saver doesn't use it.
- The data covers 1,069 locations. The years run from 1739 at the earliest to 2025.

**Display name.** A location's name is `region` if `country` is empty (only Global), else `country` if `place` is empty, else `place, country`. Names are unique, and the saved Locations option stores them.

**Order.** Global comes first, then the rest sorted by name the way Finder sorts: case-insensitive, with numbers compared by value (`localizedStandardCompare`). On Windows, `StrCmpLogicalW` is close. The saver plays the chosen locations in this order and loops. If none of the saved names exists, it plays Global.

## Timeline

Each location runs through three phases, then the next location starts.

| Phase | Length | What happens |
|---|---|---|
| Build in | `drawIn` s | The build-in style paints the stripes, progress `p` going 0 → 1 |
| Hold | 15 s | The finished picture, unchanged |
| Build out | `drawIn` s | The full picture, with the build-out style painting black over it, progress `e` going 0 → 1 |

The saver redraws at 30 fps and skips redraws during the hold, because nothing moves. The background is black.

These things are set when each location starts (`show`, line 101):

- A random permutation of the years, `order`, for Scatter. A random permutation of the `years × 12` tiles, `tileOrder`, for Mosaic. The build out reuses both, so it erases in the order it built.
- The styles for this cycle. A style other than Random is used as is. Random draws from a shuffled bag of all nine styles, and when the bag empties it refills, swapping so the new first draw differs from the last one. Build In and Build Out each have their own bag, and both reset whenever the options change.
- The label corner moves one step clockwise (see Label).

## Drawing

Let `n` be the number of years, `W` × `H` the view size and `p` the progress, from 0 to 1. Stripe `i` (0-based, left to right) spans `x0 = round(i·W/n)` to `x1 = round((i+1)·W/n)` and the full height. Rounding to whole pixels keeps neighbouring stripes from leaving seams.

Helpers, used below:

```
clamp(v)  = min(1, max(0, v))
smooth(v) = v·v·(3 − 2v)                       // smoothstep
wave(style) = max(1, n/4)   for Rise
              max(1, n/14)  for Drop
              max(1, n/8)   for Flip
              max(1, n/20)  for everything else
waveAt(i) = clamp((p·(n + wave) − i) / wave)   // stripe i's progress through a left-to-right wave
```

**Build out.** Paint every stripe at full opacity, then run the build-out style with progress `e`, with every stripe's colour replaced by black. For Flip and Blinds, darkening black still gives black.

### Styles

| Style | Per stripe `i` |
|---|---|
| Sweep | Full stripe at alpha `clamp(p·n − i)`. One stripe fades in at a time, left to right. |
| Rise | Rectangle from the bottom edge, height `round(H · smooth(waveAt(i)))`, alpha 1. |
| Scatter | Full stripe at alpha `clamp((p·(n + wave) − order[i]) / wave)`. Stripes appear in random order, with about a twentieth of them fading at once. |
| Fade | Full stripe at alpha `smooth(p)`. Everything fades in together. |
| Drop | With `q = waveAt(i)`, skip if `q = 0`. Otherwise draw the full stripe shifted up by `round(H · (1 − dropFall(q)))`, so it falls from one screen height above and lands. |
| Flip | With `q = smooth(waveAt(i))`, a rectangle of width `(x1 − x0)·q`, centred on the stripe, full height. Its colour is mixed with black by `0.6·(1 − q)`, so it is darker while edge-on. |
| Iris | Every stripe at alpha 1 once `p > 0`, clipped to a circle at the view's centre with radius `smooth(p) · √(W² + H²) / 2`. |
| Mosaic | The stripe is cut into 12 tiles from bottom to top, with tile edges at `round(row·H/12)`. With `cells = n·12` and `rank = tileOrder[i·12 + row]`, each tile has alpha `clamp((p·cells·1.05 − rank) / (cells/20))`. |
| Blinds | See below. |

**dropFall(t)** is a fall under gravity followed by two small bounces, with heights 0.06 and 0.015 of the screen:

```
h1 = 0.06, h2 = 0.015, b1 = 2·√h1, b2 = 2·√h2
u = t · (1 + b1 + b2)
if u < 1:        return u²
u −= 1
if u < b1:       v = u − b1/2; return 1 − (h1 − v²)
u −= b1
if u < b2:       v = u − b2/2; return 1 − (h2 − v²)
return 1
```

**Blinds** (`drawBlinds`, line 262) imitates Keynote's Blinds. The screen is split into 20 vertical slats of width `W/20`, independent of the stripes. Each slat swings from edge-on to facing the viewer, in perspective.

For slat `k` (0–19):

```
q     = smooth(clamp((p − 0.7·k/19) / 0.3))   // each slat turns in 30% of the time; starts spread over the rest
skip if q = 0
angle = (1 − q) · π/2
left  = k·W/20,  centre = left + W/40,  focal = H
project(x): u = x − centre
            s = focal / (focal + u·sin(angle))
            return (centre + u·cos(angle)·s,  H/2 · s)   // screen x, half-height
```

Each stripe's part of the slat, from `max(left, i·W/n)` to `min(left + W/20, (i+1)·W/n)`, is drawn as a quadrilateral. Its left edge is at `project(x0)` and its right edge at `project(x1)`, both centred vertically. The right edge is pushed out by 0.5 px so antialiasing leaves no seams. The colour is mixed with black by `0.6·(1 − q)`.

## Label

The label is drawn only if Show location and years is on.

- **Text:** `"<name>  <firstYear>–<year>"`, with two spaces and an en dash.
- **Year during the build in:** for Sweep, `lead = p·n`. For Rise, Drop and Flip, `lead = p·(n + wave)`. For the other styles, `lead = n`, so they show the last year from the start. The year shown is `firstYear + max(0, min(n, ceil(lead)) − 1)`, so it never goes below `firstYear`.
- **Year during the hold and build out:** the last year. During the build out the label fades with opacity `1 − smooth(e)`.
- **Size:** `max(10, labelSize · viewHeight / screenHeight)`, so the label shrinks in the small preview.
- **Style:** the chosen font at medium weight, white at 75% opacity, with a black shadow at 50% opacity, blur radius `size/4` and no offset.
- **Position:** a margin of `1.5·size` from two edges. The corner cycles clockwise through bottom-left, top-left, top-right and bottom-right, one step per location, so no pixels show the same text every cycle.

## Reference frames

`tools/render` renders a style's frames to PNG, using the Global series with the label off and the same style for build in and build out. The defaults are 960 × 540 at 30 fps with a 3-second build. It needs a Mac. Frames rendered from it are the easiest way to check a port against the original.

```sh
swiftc -O -module-name Stripes -framework ScreenSaver -framework AppKit -o /tmp/render *.swift tools/render/main.swift
cp Resources/stripes.json /tmp/
/tmp/render <style> <out-dir> [width height fps seconds [in]]   # e.g. /tmp/render mosaic /tmp/frames 640 360 24 14 in
```

Without `in`, it renders the build in, one second of the hold and the build out. With `in`, it renders the build in and 1.5 seconds of the finished picture.
