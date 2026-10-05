using System.Globalization;

namespace Stripes;

// An sRGB colour from the shared palette.
public readonly record struct Rgb(byte R, byte G, byte B)
{
    public static readonly Rgb Black = new(0, 0, 0);

    // Parses six hex digits with no leading '#', the form stripes.json uses.
    public static Rgb Parse(string hex)
    {
        if (hex.Length != 6 || !uint.TryParse(hex, NumberStyles.AllowHexSpecifier, CultureInfo.InvariantCulture, out var v))
        {
            throw new FormatException($"'{hex}' is not a six-digit hex colour");
        }
        return new((byte)(v >> 16), (byte)(v >> 8), (byte)v);
    }

    public override string ToString() => $"{R:x2}{G:x2}{B:x2}";
}
