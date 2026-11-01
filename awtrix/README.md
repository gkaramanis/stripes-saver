# Stripes for AWTRIX clocks

The warming stripes as an app for [AWTRIX NG](https://blueforcer.github.io/awtrix-ng/), made for the Ulanzi TC002 and its 52×16 screen. It has the same ten styles and all 1,069 locations as the macOS version, and follows [SPEC.md](../SPEC.md) where a 52-pixel screen allows.

Each time the app comes round in the clock's rotation, it shows the next location. A title card with the name and years comes first. Then the stripes build in, hold and build out. The screen is 52 pixels wide, so each location's years are averaged into 52 stripes. Grey means no data.

## Install

Install it from the [AWTRIX Hub](https://awtrix.de/scripts) by searching for Stripes, or by hand. To install by hand, open the clock's web UI, go to Scripts, import `stripes.be` and save it as `Stripes`. Or use the API:

```sh
curl -X PUT http://<clock>/api/v1/apps/script/Stripes \
  --data-binary @awtrix/stripes.be -H 'Content-Type:'
```

The app runs offline, because all the data is in the script.

## Options

The options are in the app's settings in the web UI.

- **Places:** names separated by semicolons, played in that order. Write a full name (`Uppsala, Sweden`), a place on its own (`Uppsala`), a country, a region (`Europe`) or `all`. [locations.txt](locations.txt) lists every name.
- **Order:** list or shuffled.
- **Build in and Build out:** the ten styles, or Random. Build out can also be None, which leaves the stripes on screen until the clock's own transition takes them away.
- **Build time, Show name and years, Duration.**

Two styles have other names here. On columns one pixel wide, Flip opens from the middle row, so it's called Open, and Mosaic dissolves pixel by pixel, so it's called Dissolve. The title card waits out the clock's transition, so a slow fade doesn't hide it.

## Building

```sh
python3 awtrix/stripes.py   # refresh the location table in stripes.be and locations.txt from data/stripes.json
```

## Data and credit

Warming stripes by [Ed Hawkins](https://edhawkins.org/), University of Reading, under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Colors sampled from [showyourstripes.info](https://showyourstripes.info) and animated. The app's description on the clock carries the credit.
