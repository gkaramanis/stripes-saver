"""Build data/stripes.json by sampling one colour per year from every
official Show Your Stripes image (showyourstripes.info, CC BY 4.0, Ed Hawkins).

Images are cached in data/cache/, so reruns only download what is missing.
Delete data/cache/ to pick up a new year of data.
"""
import json
import re
import string
import sys
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image

SITE = "https://showyourstripes.info"
HERE = Path(__file__).parent
CACHE = HERE / "cache"

# Each year is stored as one character indexing into the shared palette.
KEYS = string.digits + string.ascii_letters


def fetch(url):
    # The site returns 403 to urllib's default user agent.
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    return urllib.request.urlopen(req, timeout=60).read()


def image_paths():
    html = fetch(SITE + "/").decode()
    bundle = re.search(r"/js/app\.[0-9a-f]+\.js", html).group(0)
    js = fetch(SITE + bundle).decode()
    return sorted(set(re.findall(r'display_link:"/stripes/([^"]+)"', js)))


def download(path):
    dest = CACHE / urllib.parse.unquote(path)
    if not dest.exists():
        dest.write_bytes(fetch(f"{SITE}/stripes/{path}"))
    return dest


def parse_name(path):
    # REGION-COUNTRY-PLACE-FROM-TO-SOURCE.png; PLACE is "<All of X>" for a whole country.
    m = re.fullmatch(r"([^-]*)-([^-]*)-(.*)-(\d{4})-(\d{4})-([A-Z]{2})\.png", urllib.parse.unquote(path))
    region, country, place, y0, y1, source = m.groups()
    tidy = lambda s: s.replace("_", " ")
    if region == "GLOBE":
        return "Global", "", "", int(y0), int(y1), source
    if place.startswith("<All of"):
        place = ""
    if country == "<All of Ocean>":
        country = "All oceans"
    return tidy(region.title()), tidy(country), tidy(place), int(y0), int(y1), source


def sample(file, n):
    im = Image.open(file).convert("RGB")
    w, h = im.size
    cols = []
    for i in range(n):
        xl, xc, xr = (int((i + f) * w / n) for f in (0.2, 0.5, 0.8))
        px = {im.getpixel((xl, 5)), im.getpixel((xc, h // 2)), im.getpixel((xr, h - 5))}

        # A stripe that isn't uniform means the image has a margin or a different year range.
        if len(px) > 1:
            return None
        cols.append("%02x%02x%02x" % px.pop())
    return cols


def main():
    CACHE.mkdir(exist_ok=True)
    paths = image_paths()
    print(f"{len(paths)} images", file=sys.stderr)

    with ThreadPoolExecutor(8) as pool:
        files = list(pool.map(download, paths))

    palette, locations, skipped, seen = [], [], [], set()
    for path, file in zip(paths, files):
        region, country, place, y0, y1, source = parse_name(path)

        # Some countries (Egypt, Cyprus) are listed under two regions with identical data.
        if (country, place) in seen:
            continue
        seen.add((country, place))

        cols = sample(file, y1 - y0 + 1)
        if cols is None:
            skipped.append(path)
            continue
        for c in cols:
            if c not in palette:
                palette.append(c)
        locations.append({
            "region": region, "country": country, "place": place,
            "firstYear": y0, "source": source,
            "stripes": "".join(KEYS[palette.index(c)] for c in cols),
        })

    if len(palette) > len(KEYS):
        sys.exit(f"{len(palette)} colours; too many for one character each")
    for p in skipped:
        print("skipped (non-uniform stripes):", p, file=sys.stderr)
    print(f"{len(locations)} locations, {len(palette)} colours", file=sys.stderr)

    with open(HERE / "stripes.json", "w") as f:
        json.dump({"palette": palette, "locations": locations}, f, separators=(",", ":"))


if __name__ == "__main__":
    main()
