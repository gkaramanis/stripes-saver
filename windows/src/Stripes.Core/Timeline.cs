namespace Stripes;

// What to draw at one moment: a location partway through its build in, hold or build out.
public sealed record FrameState(
    Location Location,
    bool Building,
    double P,
    double E,
    DrawStyle StyleIn,
    DrawStyle StyleOut,
    int[] Order,
    int[] TileOrder,
    int Corner);

// Steps through the chosen locations: build in, a 15-second hold, build out, then the next
// location. A port of show() and animateOneFrame() in macos/StripesView.swift.
public sealed class Timeline
{
    public const double Hold = 15;
    public const int MosaicRows = 12;

    readonly IReadOnlyList<Location> locations;
    readonly DrawStyle chosenIn, chosenOut;
    readonly StyleDeck deckIn = new(), deckOut = new();
    readonly double duration;
    readonly Random random;

    int index;
    double start;
    bool drewStill;
    int[] order = [], tileOrder = [];
    DrawStyle styleIn, styleOut;

    // Which corner holds the label: 0 bottom-left, then clockwise, one step per location.
    // macOS steps it twice before the first location (apply() and startAnimation() both call
    // show()), so the first label sits top-right. Starting at 1 matches that.
    int corner = 1;

    public Timeline(IReadOnlyList<Location> locations, SaverSettings settings, Random random, double now)
    {
        if (locations.Count == 0) throw new ArgumentException("No locations to play", nameof(locations));
        this.locations = locations;
        this.random = random;
        chosenIn = settings.Style;
        chosenOut = settings.ExitStyle;
        duration = settings.DrawIn;
        Show(0, now);
    }

    // Seconds from the start of one location to the start of the next.
    public double CycleLength => duration + Hold + duration;

    // Advances to the next location when this one is done. Returns the frame to draw, or null
    // during the hold once its first frame has been drawn, because nothing moves then.
    public FrameState? Tick(double now)
    {
        if (now - start > CycleLength) Show(index + 1, now);

        var t = now - start;
        var still = t >= duration && t <= duration + Hold;
        if (still && drewStill) return null;
        drewStill = still;
        return StateAt(now);
    }

    // The frame for any moment in the current location, e.g. to repaint after WM_PAINT.
    public FrameState StateAt(double now)
    {
        var t = now - start;
        var building = t < duration + Hold;
        return new FrameState(
            locations[index],
            building,
            P: Math.Min(1, t / duration),
            E: building ? 0 : Math.Min(1, (t - duration - Hold) / duration),
            styleIn,
            styleOut,
            order,
            tileOrder,
            corner);
    }

    void Show(int i, double now)
    {
        index = i % locations.Count;
        start = now;
        drewStill = false;
        var n = locations[index].YearCount;
        order = Permutation(n);
        tileOrder = Permutation(n * MosaicRows);
        styleIn = deckIn.Next(chosenIn, random);
        styleOut = deckOut.Next(chosenOut, random);
        corner = (corner + 1) % 4;
    }

    int[] Permutation(int n)
    {
        var p = Enumerable.Range(0, n).ToArray();
        random.Shuffle(p);
        return p;
    }
}
