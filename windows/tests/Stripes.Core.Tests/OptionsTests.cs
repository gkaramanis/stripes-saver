namespace Stripes.Tests;

public class SettingsCodecTests
{
    static SaverSettings Read(params (string Name, object Value)[] values)
    {
        var map = values.ToDictionary(v => v.Name, v => v.Value);
        return SettingsCodec.Read(name => map.GetValueOrDefault(name));
    }

    [Fact]
    public void Nothing_stored_gives_the_defaults()
    {
        // Records compare lists by reference, so the locations are compared on their own.
        var s = Read();
        Assert.Equal(new SaverSettings() with { Locations = [] }, s with { Locations = [] });
        Assert.Equal(["Global"], s.Locations);
    }

    [Fact]
    public void Round_trips()
    {
        var s = new SaverSettings
        {
            Style = DrawStyle.Random, ExitStyle = DrawStyle.Blinds, DrawIn = 20, ShowLabel = false,
            LabelFont = "Georgia", LabelSize = 30, Locations = ["Global", "Sweden"],
        };
        var stored = SettingsCodec.Write(s).ToDictionary(v => v.Name, v => v.Value);
        var back = SettingsCodec.Read(name => stored.GetValueOrDefault(name));
        Assert.Equal(s with { Locations = [] }, back with { Locations = [] });
        Assert.Equal(s.Locations, back.Locations);
    }

    [Fact]
    public void Stored_types_and_keys_match_the_design()
    {
        var stored = SettingsCodec.Write(new SaverSettings()).ToDictionary(v => v.Name, v => v.Value);
        Assert.Equal("sweep", stored["style"]);
        Assert.Equal("fade", stored["exitStyle"]);
        Assert.Equal(14, stored["drawIn"]);
        Assert.Equal(1, stored["showLabel"]);
        Assert.Equal("systemMono", stored["labelFont"]);
        Assert.Equal(24, stored["labelSize"]);
        Assert.Equal(new[] { "Global" }, stored["locations"]);
    }

    [Fact]
    public void Out_of_range_numbers_are_clamped()
    {
        var s = Read(("drawIn", 1), ("labelSize", 500));
        Assert.Equal(5, s.DrawIn);
        Assert.Equal(72, s.LabelSize);
    }

    [Fact]
    public void Unusable_values_fall_back_to_defaults()
    {
        var s = Read(("style", "wobble"), ("exitStyle", 3), ("drawIn", "fast"), ("labelFont", ""), ("locations", new[] { "" }));
        Assert.Equal(DrawStyle.Sweep, s.Style);
        Assert.Equal(DrawStyle.Fade, s.ExitStyle);
        Assert.Equal(14, s.DrawIn);
        Assert.Equal("systemMono", s.LabelFont);
        Assert.Equal(["Global"], s.Locations);
    }
}

public class LocationSearchTests
{
    static readonly StripesData Data = StripesData.LoadEmbedded();

    static List<string> Names(string query, IReadOnlySet<string>? only = null) =>
        LocationSearch.Filter(Data.Locations, query, only).Select(l => l.Name).ToList();

    [Theory]
    [InlineData("zurich", "Zürich, Switzerland")]
    [InlineData("ZÜRICH", "Zürich, Switzerland")]
    [InlineData("montreal", "Montréal, Canada")]
    [InlineData("reykjavik", "Reykjavík, Iceland")]
    [InlineData("sao tome", "São Tomé and Principe")]
    public void Ignores_case_and_diacritics(string query, string expected) =>
        Assert.Contains(expected, Names(query));

    [Fact]
    public void Matches_region_names()
    {
        var europe = Names("europe");
        Assert.Contains("Sweden", europe);
        Assert.Contains("Zürich, Switzerland", europe);
        Assert.DoesNotContain("Montréal, Canada", europe);
    }

    [Fact]
    public void Empty_query_keeps_everything_in_order()
    {
        Assert.Equal(Data.Locations.Select(l => l.Name), Names("  "));
    }

    [Fact]
    public void Selected_only()
    {
        var only = new HashSet<string> { "Sweden", "Global", "Zürich, Switzerland" };
        Assert.Equal(["Global", "Sweden", "Zürich, Switzerland"], Names("", only));
        Assert.Equal(["Sweden"], Names("swe", only));
    }

    [Fact]
    public void No_match() => Assert.Empty(Names("qqqxyz"));
}
