namespace Stripes.Tests;

public class LabelTests
{
    static readonly Location Global = StripesData.LoadEmbedded().Global;  // 1850–2025, n = 176

    static FrameState Frame(DrawStyle styleIn, double p, bool building = true, double e = 0, int corner = 2) =>
        new(Global, building, p, e, styleIn, DrawStyle.Fade, [], [], corner);

    [Fact]
    public void Text_has_two_spaces_and_an_en_dash() =>
        Assert.Equal("Global  1850–2025", Label.For(Frame(DrawStyle.Fade, 1)).Text);

    [Theory]
    [InlineData(0.0, 1850)]                 // never below the first year
    [InlineData(1.0 / 176, 1850)]           // lead 1 → first stripe
    [InlineData(1.5 / 176, 1851)]           // lead 1.5 rounds up to the second stripe
    [InlineData(0.5, 1937)]                 // lead 88
    [InlineData(1.0, 2025)]
    public void Sweep_year_follows_the_leading_stripe(double p, int year) =>
        Assert.Equal(year, Label.For(Frame(DrawStyle.Sweep, p)).Year);

    [Fact]
    public void Rise_lead_includes_the_wave()
    {
        // Rise's wave is n/4 = 44, so at p = 0.5 the lead is 0.5 × 220 = 110 → 1850 + 109.
        Assert.Equal(1959, Label.For(Frame(DrawStyle.Rise, 0.5)).Year);
        // The lead passes n before p = 1, and the year stops at the last one.
        Assert.Equal(2025, Label.For(Frame(DrawStyle.Rise, 0.9)).Year);
    }

    [Theory]
    [InlineData(DrawStyle.Scatter)]
    [InlineData(DrawStyle.Fade)]
    [InlineData(DrawStyle.Blinds)]
    [InlineData(DrawStyle.Iris)]
    [InlineData(DrawStyle.Mosaic)]
    public void Other_styles_show_the_last_year_from_the_start(DrawStyle style) =>
        Assert.Equal(2025, Label.For(Frame(style, 0)).Year);

    [Fact]
    public void Build_out_shows_the_last_year_and_fades()
    {
        var label = Label.For(Frame(DrawStyle.Sweep, 1, building: false, e: 0.5));
        Assert.Equal(2025, label.Year);
        Assert.Equal(0.5, label.Alpha, 9);
        Assert.Equal(0, Label.For(Frame(DrawStyle.Sweep, 1, building: false, e: 1)).Alpha, 9);
    }

    [Fact]
    public void Size_scales_with_the_preview_but_not_below_ten()
    {
        Assert.Equal(24, Label.Size(24, 1080, 1080));
        Assert.Equal(12, Label.Size(24, 540, 1080));
        Assert.Equal(10, Label.Size(24, 100, 1080));
    }

    [Fact]
    public void Corners_sit_a_margin_from_two_edges()
    {
        const double size = 20, w = 100, h = 30, W = 1000, H = 500;  // margin 30
        Assert.Equal((30.0, 440.0), Label.Position(Label.BottomLeft, size, w, h, W, H));
        Assert.Equal((30.0, 30.0), Label.Position(Label.TopLeft, size, w, h, W, H));
        Assert.Equal((870.0, 30.0), Label.Position(Label.TopRight, size, w, h, W, H));
        Assert.Equal((870.0, 440.0), Label.Position(Label.BottomRight, size, w, h, W, H));
    }
}
