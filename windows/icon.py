"""Draw the global stripes into windows/src/Stripes/Stripes.ico, the icon Explorer shows
for Stripes.scr. Like macos/thumbnail.py, but square."""
import json
import string
from pathlib import Path

from PIL import Image

KEYS = string.digits + string.ascii_letters
HERE = Path(__file__).parent

data = json.load(open(HERE.parent / "data" / "stripes.json"))
glob = next(l for l in data["locations"] if l["region"] == "Global")
colors = [tuple(bytes.fromhex(data["palette"][KEYS.index(c)])) for c in glob["stripes"]]

# Draw large and scale down so stripes blend smoothly at icon size.
n = len(colors)
big = Image.new("RGB", (n * 8, n * 8))
for i, c in enumerate(colors):
    big.paste(c, (i * 8, 0, (i + 1) * 8, n * 8))

sizes = [16, 20, 24, 32, 40, 48, 64, 256]
big.resize((256, 256), Image.LANCZOS).convert("RGBA").save(
    HERE / "src" / "Stripes" / "Stripes.ico", sizes=[(s, s) for s in sizes])
