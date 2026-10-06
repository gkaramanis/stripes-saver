using System.Text.Json;
using System.Text.Json.Serialization;

namespace Stripes;

// The contents of data/stripes.json: a shared palette and every location's stripes.
// SPEC.md, Data describes the format; data/sample.py builds the file.
public sealed class StripesData
{
    public const string GlobalName = "Global";

    // Each year is one character indexing the palette: '0' is palette[0], 'Z' is palette[61].
    internal const string Keys = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

    readonly Dictionary<string, Location> byName;

    StripesData(IReadOnlyList<Rgb> palette, List<Location> locations)
    {
        Palette = palette;
        locations.Sort(CompareForDisplay);
        Locations = locations;
        byName = new Dictionary<string, Location>(StringComparer.Ordinal);
        foreach (var l in locations)
        {
            if (!byName.TryAdd(l.Name, l))
            {
                throw new InvalidDataException($"Two locations are named '{l.Name}'");
            }
        }
        Global = Find(GlobalName) ?? throw new InvalidDataException($"No location named '{GlobalName}'");
    }

    public IReadOnlyList<Rgb> Palette { get; }

    // Global first, then the rest by name in Explorer order.
    public IReadOnlyList<Location> Locations { get; }

    public Location Global { get; }

    public Location? Find(string name) => byName.GetValueOrDefault(name);

    // The saved Locations option, as the locations to play: the ones that still exist, in
    // display order. Falls back to Global if none do.
    public IReadOnlyList<Location> Resolve(IEnumerable<string> names)
    {
        var wanted = new HashSet<string>(names, StringComparer.Ordinal);
        var found = Locations.Where(l => wanted.Contains(l.Name)).ToList();
        return found.Count > 0 ? found : [Global];
    }

    public static StripesData LoadEmbedded()
    {
        using var stream = typeof(StripesData).Assembly.GetManifestResourceStream("stripes.json")
            ?? throw new InvalidOperationException("stripes.json is not embedded");
        return Load(stream);
    }

    public static StripesData Load(Stream json)
    {
        var file = JsonSerializer.Deserialize(json, StripesJsonContext.Default.StripesFile)
            ?? throw new InvalidDataException("stripes.json is empty");
        if (file.Palette is not { Count: > 0 } paletteHex)
        {
            throw new InvalidDataException("stripes.json has no palette");
        }
        if (paletteHex.Count > Keys.Length)
        {
            throw new InvalidDataException($"{paletteHex.Count} palette colours; at most {Keys.Length} fit one character each");
        }
        if (file.Locations is not { Count: > 0 } entries)
        {
            throw new InvalidDataException("stripes.json has no locations");
        }

        var palette = paletteHex.Select(Rgb.Parse).ToArray();
        var locations = new List<Location>(entries.Count);
        foreach (var e in entries)
        {
            var name = Location.DisplayName(e.Region ?? "", e.Country ?? "", e.Place ?? "");
            if (string.IsNullOrEmpty(e.Stripes))
            {
                throw new InvalidDataException($"'{name}' has no stripes");
            }
            locations.Add(new Location(e.Region ?? "", e.Country ?? "", e.Place ?? "", e.FirstYear, e.Source ?? "",
                Decode(e.Stripes, palette, name)));
        }
        return new StripesData(palette, locations);
    }

    static Rgb[] Decode(string stripes, Rgb[] palette, string name)
    {
        var colours = new Rgb[stripes.Length];
        for (var i = 0; i < stripes.Length; i++)
        {
            var index = Keys.IndexOf(stripes[i]);
            if (index < 0 || index >= palette.Length)
            {
                throw new InvalidDataException($"'{name}' year {i} has key '{stripes[i]}', which is not in the palette");
            }
            colours[i] = palette[index];
        }
        return colours;
    }

    static int CompareForDisplay(Location a, Location b) =>
        a.IsGlobal != b.IsGlobal ? (a.IsGlobal ? -1 : 1)
        : LogicalStringComparer.Instance.Compare(a.Name, b.Name);
}

sealed class StripesFile
{
    public List<string>? Palette { get; set; }
    public List<LocationEntry>? Locations { get; set; }
}

sealed class LocationEntry
{
    public string? Region { get; set; }
    public string? Country { get; set; }
    public string? Place { get; set; }
    public int FirstYear { get; set; }
    public string? Source { get; set; }
    public string? Stripes { get; set; }
}

// Source-generated serialization, so Native AOT needs no reflection.
[JsonSourceGenerationOptions(PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase)]
[JsonSerializable(typeof(StripesFile))]
partial class StripesJsonContext : JsonSerializerContext;
