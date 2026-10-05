using System.Globalization;

namespace Stripes;

public enum SaverMode { Configure, Show, Preview }

// The command line Windows passes a screen saver: /s, /p <hwnd>, /c[:hwnd] or nothing.
// Letters are case-insensitive, '-' works as well as '/', and a value may follow ':' or a space.
public readonly record struct ScreenSaverArgs(SaverMode Mode, nint Window)
{
    public static bool TryParse(IReadOnlyList<string> args, out ScreenSaverArgs result)
    {
        result = new(SaverMode.Configure, 0);
        if (args.Count == 0) return true;

        var first = args[0].Trim();
        if (first.Length > 0 && first[0] is '/' or '-') first = first[1..];
        if (first.Length == 0) return false;

        var rest = first[1..].TrimStart(':').Trim();
        var value = rest.Length > 0 ? rest : args.Count > 1 ? args[1].Trim() : "";

        switch (char.ToLowerInvariant(first[0]))
        {
            case 's':
                result = new(SaverMode.Show, 0);
                return true;
            case 'p':
            case 'l':  // Older Windows versions used /l for the preview.
                if (!TryParseWindow(value, out var parent) || parent == 0) return false;
                result = new(SaverMode.Preview, parent);
                return true;
            case 'c':
                if (value.Length == 0)
                {
                    result = new(SaverMode.Configure, 0);
                    return true;
                }
                if (!TryParseWindow(value, out var owner)) return false;
                result = new(SaverMode.Configure, owner);
                return true;
            default:
                return false;
        }
    }

    // Windows passes window handles in decimal; accept hex with a 0x prefix too.
    static bool TryParseWindow(string s, out nint hwnd)
    {
        hwnd = 0;
        if (s.StartsWith("0x", StringComparison.OrdinalIgnoreCase))
        {
            if (!ulong.TryParse(s.AsSpan(2), NumberStyles.AllowHexSpecifier, CultureInfo.InvariantCulture, out var hex)) return false;
            hwnd = (nint)hex;
            return true;
        }
        if (!long.TryParse(s, NumberStyles.Integer, CultureInfo.InvariantCulture, out var dec)) return false;
        hwnd = (nint)dec;
        return true;
    }
}
