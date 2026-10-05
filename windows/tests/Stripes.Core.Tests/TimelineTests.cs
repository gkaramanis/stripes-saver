namespace Stripes.Tests;

public class TimelineTests
{
    static readonly StripesData Data = StripesData.LoadEmbedded();

    static Timeline Make(SaverSettings? settings = null, params string[] names) =>
        new(Data.Resolve(names.Length > 0 ? names : ["Global"]), settings ?? new SaverSettings(), new Random(1), now: 100);

    [Fact]
    public void Deck_returns_a_chosen_style_as_is()
    {
        var deck = new StyleDeck();
        Assert.Equal(DrawStyle.Iris, deck.Next(DrawStyle.Iris, new Random(1)));
        Assert.Equal(DrawStyle.Iris, deck.Current);
    }

    [Fact]
    public void Random_deals_every_style_before_repeating_and_never_twice_in_a_row()
    {
        var deck = new StyleDeck();
        var random = new Random(7);
        var dealt = Enumerable.Range(0, 9 * 50).Select(_ => deck.Next(DrawStyle.Random, random)).ToList();
        for (var round = 0; round < 50; round++)
        {
            Assert.Equal(DrawStyles.Animated.OrderBy(s => s), dealt.Skip(round * 9).Take(9).OrderBy(s => s));
        }
        for (var i = 1; i < dealt.Count; i++)
        {
            Assert.NotEqual(dealt[i - 1], dealt[i]);
        }
        // The deck starts as if Sweep was last, so the first deal is never Sweep.
        Assert.NotEqual(DrawStyle.Sweep, dealt[0]);
    }

    [Fact]
    public void Phases_follow_the_spec()
    {
        var timeline = Make(new SaverSettings { Style = DrawStyle.Sweep, ExitStyle = DrawStyle.Fade });  // 14 s, 15 s, 14 s

        var f = timeline.StateAt(100 + 7);
        Assert.True(f.Building);
        Assert.Equal(0.5, f.P, 6);

        f = timeline.StateAt(100 + 20);  // hold
        Assert.True(f.Building);
        Assert.Equal(1, f.P);

        f = timeline.StateAt(100 + 14 + 15 + 7);
        Assert.False(f.Building);
        Assert.Equal(0.5, f.E, 6);
        Assert.Equal(DrawStyle.Sweep, f.StyleIn);
        Assert.Equal(DrawStyle.Fade, f.StyleOut);
    }

    [Fact]
    public void Random_by_default_deals_real_styles()
    {
        var timeline = Make();
        var f = timeline.StateAt(100);
        Assert.NotEqual(DrawStyle.Random, f.StyleIn);
        Assert.NotEqual(DrawStyle.Random, f.StyleOut);
    }

    [Fact]
    public void Hold_is_drawn_once()
    {
        var timeline = Make();
        Assert.NotNull(timeline.Tick(100 + 1));
        Assert.NotNull(timeline.Tick(100 + 14.5));  // first frame of the hold
        Assert.Null(timeline.Tick(100 + 15));
        Assert.Null(timeline.Tick(100 + 28));
        Assert.NotNull(timeline.Tick(100 + 30));    // build out
    }

    [Fact]
    public void Locations_advance_and_loop_and_the_label_corner_moves_clockwise()
    {
        var timeline = Make(null, "Sweden", "Norway");  // played in display order: Norway, Sweden
        var cycle = timeline.CycleLength;
        var seen = new List<(string, int)>();
        for (var k = 0; k < 5; k++)
        {
            var f = timeline.Tick(100 + k * (cycle + 0.01) + 0.005)!;
            seen.Add((f.Location.Name, f.Corner));
        }
        Assert.Equal([("Norway", 2), ("Sweden", 3), ("Norway", 0), ("Sweden", 1), ("Norway", 2)], seen);
    }

    [Fact]
    public void Orders_are_permutations_sized_to_the_location()
    {
        var f = Make().StateAt(100);
        var n = f.Location.YearCount;
        Assert.Equal(Enumerable.Range(0, n), f.Order.OrderBy(i => i));
        Assert.Equal(Enumerable.Range(0, n * Timeline.MosaicRows), f.TileOrder.OrderBy(i => i));
    }

    [Fact]
    public void Settings_durations_are_used()
    {
        var timeline = Make(new SaverSettings { DrawIn = 5 });
        Assert.Equal(5 + 15 + 5, timeline.CycleLength);
        Assert.Equal(0.5, timeline.StateAt(102.5).P, 6);
    }
}
