"""Fill the place table in awtrix/stripes.be from data/stripes.json.

Every location keeps the saver's name and order. Its years are averaged into 52
columns on the 18-step cold-to-warm scale and written as one letter per column
(a = coldest, r = warmest, - = no data), so 176 or 287 years fit the 52x16 screen.

It also writes locations.txt, every name the Places setting accepts, by region.

    python3 awtrix/stripes.py
"""

import json
import pathlib
import re
import unicodedata

HERE = pathlib.Path(__file__).resolve().parent
DATA = HERE.parent / "data/stripes.json"
SCRIPT = HERE / "stripes.be"
LIST = HERE / "locations.txt"
WIDTH = 52

# ColorBrewer Blues and Reds plus the two extremes, coldest first
SCALE = [
    "001944", "08306b", "08519c", "2171b5", "4292c6", "6baed6", "9ecae1",
    "c6dbef", "deebf7", "fee0d2", "fcbba1", "fc9272", "fb6a4a", "ef3b2c",
    "cb181d", "a50f15", "67000d", "440007",
]


def name(loc):
    if not loc["country"]:
        return loc["region"]
    return loc["country"] if not loc["place"] else f'{loc["place"]}, {loc["country"]}'


# Close to Finder's order: no case or accents, numbers by value
def sort_key(n):
    plain = unicodedata.normalize("NFKD", n).encode("ascii", "ignore").decode().casefold()
    return (n != "Global", [int(t) if t.isdigit() else t for t in re.split(r"(\d+)", plain)])


def columns(stripes, level):
    years = [level[int(ch, 36)] for ch in stripes]
    n = len(years)
    out = ""
    for x in range(WIDTH):
        lo = x * n // WIDTH
        chunk = [v for v in years[lo:max((x + 1) * n // WIDTH, lo + 1)] if v >= 0]
        out += chr(97 + round(sum(chunk) / len(chunk))) if chunk else "-"
    return out


HEADER = """Stripes locations for AWTRIX

Every location the Stripes app can show, by region. Each country comes first,
followed by its cities. Type names into the Places setting, separated by
semicolons, in the order they should play:

    Global; Sweden; Stockholm, Sweden

A region's name (Europe) plays all its locations, and all plays every one.
"""


# Lowercases A-Z only, like jq's ascii_downcase in steam/build.sh
def ascii_lower(s):
    return "".join(chr(ord(c) + 32) if "A" <= c <= "Z" else c for c in s)


# Grouped and ordered like steam/locations.txt
def write_list(locs):
    groups = {}
    for loc in locs:
        groups.setdefault(loc["region"], []).append(loc)
    parts = [HEADER]
    for region in sorted(groups, key=lambda r: (r != "Global", r)):
        rows = sorted(groups[region], key=lambda l: (ascii_lower(l["country"]), ascii_lower(l["place"])))
        parts.append(region + "\n\n" + "\n".join(name(l) for l in rows) + "\n")
    LIST.write_text("\n".join(parts))


def main():
    data = json.loads(DATA.read_text())
    level = {i: SCALE.index(c) if c in SCALE else -1 for i, c in enumerate(data["palette"])}
    locs = sorted(data["locations"], key=lambda l: sort_key(name(l)))
    rows = []
    for loc in locs:
        last = loc["firstYear"] + len(loc["stripes"]) - 1
        rows.append(f'    [{json.dumps(name(loc), ensure_ascii=False)}, "{loc["region"]}", '
                    f'{loc["firstYear"]}, {last}, "{columns(loc["stripes"], level)}"],')
    table = "\n".join(["  static PLACES = ["] + rows + ["  ]"])

    src = SCRIPT.read_text()
    begin, end = "  # BEGIN DATA\n", "  # END DATA\n"
    head, rest = src.split(begin)
    _, tail = rest.split(end)
    SCRIPT.write_text(head + begin + table + "\n" + end + tail)
    print(f"{len(rows)} places written to {SCRIPT}")
    write_list(data["locations"])
    print(f"Every name listed in {LIST}")


main()
