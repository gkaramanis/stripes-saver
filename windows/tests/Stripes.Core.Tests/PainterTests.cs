namespace Stripes.Tests;

public class PainterTests
{
    static readonly Location Global = StripesData.LoadEmbedded().Global;
    const double W = 960, H = 540;

    static List<DrawCommand> Paint(DrawStyle style, double p, bool erase = false)
    {
        var n = Global.YearCount;
        var order = Enumerable.Range(0, n).ToArray();
        var tiles = Enumerable.Range(0, n * Timeline.MosaicRows).ToArray();
        var list = new DrawList();
        list.Reset(W, H);
        Painter.Paint(list, Global, style, p, erase, order, tiles);
        return list.Commands.ToList();
    }

    [Fact]
    public void Smooth_and_clamp()
    {
        Assert.Equal(0, Painter.Smooth(0));
        Assert.Equal(0.5, Painter.Smooth(0.5));
        Assert.Equal(1, Painter.Smooth(1));
        Assert.Equal(0, Painter.Clamp(-2));
        Assert.Equal(1, Painter.Clamp(3));
    }

    [Fact]
    public void Round_halves_away_from_zero_like_swift()
    {
        Assert.Equal(3, Painter.Round(2.5));
        Assert.Equal(4, Painter.Round(3.5));
    }

    [Fact]
    public void DropFall_starts_at_rest_lands_and_bounces_low()
    {
        Assert.Equal(0, Painter.DropFall(0));
        Assert.Equal(1, Painter.DropFall(1));
        var samples = Enumerable.Range(0, 1001).Select(k => Painter.DropFall(k / 1000.0)).ToList();
        Assert.All(samples, v => Assert.InRange(v, 0, 1));
        // After first touching the ground it rises no higher than the first bounce (6% of the screen).
        var landed = samples.FindIndex(v => v >= 1 - 1e-9);
        Assert.All(samples.Skip(landed), v => Assert.True(v >= 1 - 0.06 - 1e-9));
    }

    [Theory]
    [InlineData(DrawStyle.Rise, 176, 44.0)]
    [InlineData(DrawStyle.Drop, 176, 176 / 14.0)]
    [InlineData(DrawStyle.Flip, 176, 22.0)]
    [InlineData(DrawStyle.Scatter, 176, 8.8)]
    [InlineData(DrawStyle.Scatter, 10, 1.0)]  // never below one stripe
    public void Wave_widths(DrawStyle style, double n, double expected) =>
        Assert.Equal(expected, Painter.Wave(style, n), 9);

    [Theory]
    [InlineData(DrawStyle.Sweep)]
    [InlineData(DrawStyle.Rise)]
    [InlineData(DrawStyle.Scatter)]
    [InlineData(DrawStyle.Fade)]
    [InlineData(DrawStyle.Drop)]
    [InlineData(DrawStyle.Flip)]
    [InlineData(DrawStyle.Mosaic)]
    [InlineData(DrawStyle.Blinds)]
    [InlineData(DrawStyle.Iris)]
    public void Nothing_is_drawn_at_the_start(DrawStyle style) =>
        Assert.DoesNotContain(Paint(style, 0), c => c.Kind is DrawKind.Rect or DrawKind.Quad);

    [Theory]
    [InlineData(DrawStyle.Sweep)]
    [InlineData(DrawStyle.Rise)]
    [InlineData(DrawStyle.Scatter)]
    [InlineData(DrawStyle.Fade)]
    [InlineData(DrawStyle.Drop)]
    [InlineData(DrawStyle.Flip)]
    [InlineData(DrawStyle.Iris)]
    public void Finished_stripes_tile_the_screen_exactly(DrawStyle style)
    {
        var rects = Paint(style, 1).Where(c => c.Kind == DrawKind.Rect).ToList();
        Assert.Equal(Global.YearCount, rects.Count);
        Assert.All(rects, r => Assert.Equal((0.0, H, 1f), (r.Y0, r.Y1, r.A)));
        Assert.Equal(0, rects[0].X0);
        Assert.Equal(W, rects[^1].X1);
        for (var i = 1; i < rects.Count; i++) Assert.Equal(rects[i - 1].X1, rects[i].X0);
        Assert.Equal(Colour.From(Global.ColourOf(2025)), new Colour(rects[^1].R, rects[^1].G, rects[^1].B));
    }

    [Fact]
    public void Mosaic_finishes_with_twelve_opaque_tiles_per_stripe()
    {
        var rects = Paint(DrawStyle.Mosaic, 1);
        Assert.Equal(Global.YearCount * 12, rects.Count);
        Assert.All(rects, r => Assert.Equal(1f, r.A));
    }

    [Fact]
    public void Sweep_reveals_left_to_right()
    {
        var rects = Paint(DrawStyle.Sweep, 0.5);
        var n = Global.YearCount;
        Assert.Equal(n / 2, rects.Count);
        Assert.All(rects, r => Assert.Equal(1f, r.A));
    }

    [Fact]
    public void Iris_is_clipped_to_a_growing_circle()
    {
        var list = Paint(DrawStyle.Iris, 0.5);
        Assert.Equal(DrawKind.PushCircleClip, list[0].Kind);
        Assert.Equal((W / 2, H / 2), (list[0].X0, list[0].Y0));
        Assert.Equal(0.5 * Math.Sqrt(W * W + H * H) / 2, list[0].X1, 9);
        Assert.Equal(DrawKind.PopClip, list[^1].Kind);
    }

    [Fact]
    public void Blinds_finish_as_flat_slats_covering_the_screen()
    {
        var quads = Paint(DrawStyle.Blinds, 1);
        Assert.All(quads, q => Assert.Equal(DrawKind.Quad, q.Kind));
        Assert.Equal(0, quads.Min(q => q.X0), 9);
        Assert.Equal(W + 0.5, quads.Max(q => q.X1), 9);
        Assert.All(quads, q => Assert.Equal((0.0, H), (q.Y0, q.Y3)));
    }

    [Fact]
    public void Erasing_paints_black()
    {
        var rects = Paint(DrawStyle.Fade, 1, erase: true);
        Assert.All(rects, r => Assert.Equal((0f, 0f, 0f), (r.R, r.G, r.B)));
    }

    [Fact]
    public void Build_out_paints_the_full_picture_then_the_exit_style_in_black()
    {
        var timeline = new Timeline([Global], new SaverSettings(), new Random(1), now: 0);
        var list = new DrawList();
        Painter.Frame(list, timeline.StateAt(14 + 15 + 7), W, H);
        var n = Global.YearCount;
        Assert.Equal(2 * n, list.Commands.Count);
        Assert.All(list.Commands.Take(n), c => Assert.Equal(1f, c.A));
        Assert.All(list.Commands.Skip(n), c => Assert.Equal((0f, 0f, 0f, (float)Painter.Smooth(0.5)), (c.R, c.G, c.B, c.A)));
    }
}
