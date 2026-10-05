"""Draw the global stripes into Resources/thumbnail.png and thumbnail@2x.png,
the images System Settings shows for the screensaver."""
import json
import string

from PIL import Image

KEYS = string.digits + string.ascii_letters

data = json.load(open("Resources/stripes.json"))
glob = next(l for l in data["locations"] if l["region"] == "Global")
colors = [tuple(bytes.fromhex(data["palette"][KEYS.index(c)])) for c in glob["stripes"]]

# Draw large and scale down so stripes blend smoothly at thumbnail size.
n = len(colors)
big = Image.new("RGB", (n * 8, 464))
for i, c in enumerate(colors):
    big.paste(c, (i * 8, 0, (i + 1) * 8, 464))

for name, size in [("thumbnail.png", (90, 58)), ("thumbnail@2x.png", (180, 116))]:
    big.resize(size, Image.LANCZOS).convert("RGBA").save(f"Resources/{name}")
