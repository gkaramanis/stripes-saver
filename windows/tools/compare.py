"""Compare frames from macos/tools/render with frames from windows/tools/Render.

Usage: python compare.py <mac-dir> <windows-dir> [tolerance]

For each frame present in both folders, reports the share of pixels whose largest channel
difference exceeds the tolerance (default 8 of 255, to allow for antialiasing), and the worst
frames. Scatter and Mosaic shuffle with an unseeded random order on macOS, so only their
first and last frames can match exactly.
"""
import sys
from pathlib import Path

from PIL import Image, ImageChops


def differing_share(a, b, tolerance):
    diff = ImageChops.difference(a, b)
    worst = diff.split()
    mask = worst[0]
    for band in worst[1:]:
        mask = ImageChops.lighter(mask, band)
    counts = mask.histogram()
    return sum(counts[tolerance + 1:]) / (a.width * a.height)


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    mac, win = Path(sys.argv[1]), Path(sys.argv[2])
    tolerance = int(sys.argv[3]) if len(sys.argv) > 3 else 8

    results = []
    for f in sorted(mac.glob("*.png")):
        other = win / f.name
        if not other.exists():
            continue
        a = Image.open(f).convert("RGB")
        b = Image.open(other).convert("RGB")
        if a.size != b.size:
            sys.exit(f"{f.name}: sizes differ, {a.size} and {b.size}")
        results.append((differing_share(a, b, tolerance), f.name))

    if not results:
        sys.exit("no frames in common")
    mean = sum(r for r, _ in results) / len(results)
    print(f"{len(results)} frames, mean {mean:.3%} of pixels differ by more than {tolerance}")
    for share, name in sorted(results, reverse=True)[:5]:
        print(f"  {name}: {share:.3%}")


if __name__ == "__main__":
    main()
