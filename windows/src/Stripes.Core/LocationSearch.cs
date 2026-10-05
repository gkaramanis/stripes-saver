using System.Runtime.InteropServices;

namespace Stripes;

// The options dialog's location filter: a search that matches location and region names,
// ignoring case and diacritics, so "zurich" finds Zürich (as on macOS), plus "selected only".
public static partial class LocationSearch
{
    public static IReadOnlyList<Location> Filter(IReadOnlyList<Location> all, string query, IReadOnlySet<string>? onlyThese = null)
    {
        query = query.Trim();
        return all.Where(l =>
                (query.Length == 0 || Contains(l.Name, query) || Contains(l.Region, query))
                && (onlyThese is null || onlyThese.Contains(l.Name)))
            .ToList();
    }

    // FindNLSStringEx rather than CompareInfo, which ignores diacritics only with ICU or NLS
    // globalization, and the saver runs in invariant mode.
    public static bool Contains(string source, string value) =>
        value.Length == 0 || FindNLSStringEx("", FindFromStart | IgnoreCase | IgnoreDiacritic,
            source, source.Length, value, value.Length, out _, 0, 0, 0) >= 0;

    const uint FindFromStart = 0x00400000;
    const uint IgnoreCase = 0x00000010;       // LINGUISTIC_IGNORECASE
    const uint IgnoreDiacritic = 0x00000020;  // LINGUISTIC_IGNOREDIACRITIC

    [LibraryImport("kernel32.dll", StringMarshalling = StringMarshalling.Utf16)]
    private static partial int FindNLSStringEx(string localeName, uint flags, string source, int sourceLength,
        string value, int valueLength, out int found, nint versionInformation, nint reserved, nint sortHandle);
}
