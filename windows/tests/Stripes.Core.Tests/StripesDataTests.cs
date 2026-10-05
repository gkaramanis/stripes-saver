using System.Text;
using System.Text.Json;

namespace Stripes.Tests;

public class StripesDataTests
{
    // The 18 official colours (ColorBrewer 8 + 8 and the two beyond-scale shades) plus the
    // grey that marks years without data.
    static readonly HashSet<string> OfficialColours =
    [
        "001944", "08306b", "08519c", "2171b5", "4292c6", "6baed6", "9ecae1", "c6dbef", "deebf7",
        "fee0d2", "fcbba1", "fc9272", "fb6a4a", "ef3b2c", "cb181d", "a50f15", "67000d", "440007",
        "7f7f7f",
    ];

    static StripesData Make(string[] palette, params (string Region, string Country, string Place, int FirstYear, string Stripes)[] locations)
    {
        var json = JsonSerializer.Serialize(new
        {
            palette,
            locations = locations.Select(l => new
            {
                region = l.Region, country = l.Country, place = l.Place,
                firstYear = l.FirstYear, source = "BK", stripes = l.Stripes,
            }),
        });
        return StripesData.Load(new MemoryStream(Encoding.UTF8.GetBytes(json)));
    }

    static readonly string[] TwoColours = ["08306b", "67000d"];
    static readonly (string, string, string, int, string) GlobalEntry = ("Global", "", "", 1850, "01");

    [Fact]
    public void Embedded_data_loads()
    {
        var data = StripesData.LoadEmbedded();
        Assert.True(data.Locations.Count > 1000);
        Assert.Same(data.Global, data.Locations[0]);
    }

    [Fact]
    public void Embedded_palette_has_only_official_colours()
    {
        var data = StripesData.LoadEmbedded();
        Assert.All(data.Palette, c => Assert.Contains(c.ToString(), OfficialColours));
    }

    [Fact]
    public void Embedded_global_matches_the_official_image()
    {
        // Checked against GLOBE---1850-2025-MO.png from showyourstripes.info.
        var global = StripesData.LoadEmbedded().Global;
        Assert.Equal(1850, global.FirstYear);
        Assert.Equal(Rgb.Parse("08519c"), global.ColourOf(1850));
        Assert.Equal(Rgb.Parse("440007"), global.ColourOf(2023));
        Assert.Equal(Rgb.Parse("440007"), global.ColourOf(2024));
        Assert.Equal(Rgb.Parse("440007"), global.ColourOf(2025));
    }

    [Fact]
    public void Display_names_follow_the_spec()
    {
        var data = Make(TwoColours,
            GlobalEntry,
            ("Europe", "Sweden", "", 1850, "01"),
            ("Europe", "Sweden", "Stockholm", 1850, "01"));
        Assert.NotNull(data.Find("Global"));
        Assert.NotNull(data.Find("Sweden"));
        Assert.NotNull(data.Find("Stockholm, Sweden"));
    }

    [Fact]
    public void Global_comes_first_then_explorer_order()
    {
        var data = Make(TwoColours,
            ("Asia", "Zeta", "", 1900, "0"),
            ("Asia", "item 10", "", 1900, "0"),
            GlobalEntry,
            ("Asia", "Item 2", "", 1900, "0"),
            ("Asia", "alpha", "", 1900, "0"));
        Assert.Equal(["Global", "alpha", "Item 2", "item 10", "Zeta"], data.Locations.Select(l => l.Name));
    }

    [Fact]
    public void Keys_index_the_palette()
    {
        var palette = Enumerable.Range(0, 62).Select(i => $"0000{i:x2}").ToArray();
        var data = Make(palette, ("Global", "", "", 2000, "09azAZ"));
        Assert.Equal([0, 9, 10, 35, 36, 61], data.Global.Colours.Select(c => (int)c.B));
        Assert.Equal(2005, data.Global.LastYear);
    }

    [Fact]
    public void Resolve_keeps_display_order_and_drops_missing_names()
    {
        var data = Make(TwoColours, GlobalEntry, ("Europe", "Sweden", "", 1850, "0"), ("Europe", "Norway", "", 1850, "0"));
        Assert.Equal(["Global", "Norway", "Sweden"], data.Resolve(["Sweden", "Gone", "Norway", "Global"]).Select(l => l.Name));
    }

    [Fact]
    public void Resolve_falls_back_to_global()
    {
        var data = Make(TwoColours, GlobalEntry, ("Europe", "Sweden", "", 1850, "0"));
        Assert.Equal([data.Global], data.Resolve(["Gone"]));
        Assert.Equal([data.Global], data.Resolve([]));
    }

    [Fact]
    public void ColourOf_rejects_years_outside_the_range()
    {
        var global = Make(TwoColours, GlobalEntry).Global;
        Assert.Throws<ArgumentOutOfRangeException>(() => global.ColourOf(1849));
        Assert.Throws<ArgumentOutOfRangeException>(() => global.ColourOf(1852));
    }

    [Theory]
    [InlineData("0!")]  // not a key
    [InlineData("02")]  // key beyond the palette
    [InlineData("")]    // no stripes
    public void Bad_stripes_are_rejected(string stripes) =>
        Assert.Throws<InvalidDataException>(() => Make(TwoColours, ("Global", "", "", 1850, stripes)));

    [Fact]
    public void Duplicate_names_are_rejected() =>
        Assert.Throws<InvalidDataException>(() => Make(TwoColours, GlobalEntry, ("Europe", "Sweden", "", 1850, "0"), ("Asia", "Sweden", "", 1850, "1")));

    [Fact]
    public void Missing_global_is_rejected() =>
        Assert.Throws<InvalidDataException>(() => Make(TwoColours, ("Europe", "Sweden", "", 1850, "0")));

    [Fact]
    public void Bad_palette_colour_is_rejected() =>
        Assert.Throws<FormatException>(() => Make(["08306", "67000d"], GlobalEntry));
}
