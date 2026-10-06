using System.Runtime.InteropServices;

namespace Stripes;

// Sorts names the way Explorer does: case-insensitive, with digit runs compared by value.
// The closest Windows match to the Finder order (localizedStandardCompare) that macOS uses.
public sealed partial class LogicalStringComparer : IComparer<string>
{
    public static readonly LogicalStringComparer Instance = new();

    public int Compare(string? x, string? y)
    {
        if (ReferenceEquals(x, y)) return 0;
        if (x is null) return -1;
        if (y is null) return 1;
        return StrCmpLogicalW(x, y);
    }

    [LibraryImport("shlwapi.dll", StringMarshalling = StringMarshalling.Utf16)]
    private static partial int StrCmpLogicalW(string psz1, string psz2);
}
