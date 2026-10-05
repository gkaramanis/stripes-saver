namespace Stripes;

// One official Show Your Stripes location: one colour per year from FirstYear to LastYear.
public sealed class Location
{
    internal Location(string region, string country, string place, int firstYear, string source, Rgb[] colours)
    {
        Region = region;
        Country = country;
        Place = place;
        FirstYear = firstYear;
        Source = source;
        Colours = colours;
        Name = DisplayName(region, country, place);
    }

    public string Region { get; }
    public string Country { get; }
    public string Place { get; }
    public int FirstYear { get; }

    // Dataset code from the official image's file name (BK, MO, NO, ...). Not shown by the saver.
    public string Source { get; }

    // Stripe colours, oldest year first.
    public IReadOnlyList<Rgb> Colours { get; }

    // The name shown in the options and the label, and stored in the Locations option.
    public string Name { get; }

    public int YearCount => Colours.Count;
    public int LastYear => FirstYear + Colours.Count - 1;

    // Only Global has no country.
    public bool IsGlobal => Country.Length == 0;

    public Rgb ColourOf(int year)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(year, FirstYear);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(year, LastYear);
        return Colours[year - FirstYear];
    }

    public override string ToString() => Name;

    // SPEC.md, Data: region if country is empty, else country if place is empty, else "place, country".
    internal static string DisplayName(string region, string country, string place) =>
        country.Length == 0 ? region
        : place.Length == 0 ? country
        : $"{place}, {country}";
}
