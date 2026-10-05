namespace Stripes;

// Deals styles for Random: every style once in a new order, never the same twice in a row.
// A port of StyleDeck in macos/StripesView.swift.
public sealed class StyleDeck
{
    readonly List<DrawStyle> bag = [];

    public DrawStyle Current { get; private set; } = DrawStyle.Sweep;

    public DrawStyle Next(DrawStyle chosen, Random random)
    {
        if (chosen != DrawStyle.Random)
        {
            Current = chosen;
            return chosen;
        }
        if (bag.Count == 0)
        {
            var styles = DrawStyles.Animated.ToArray();
            random.Shuffle(styles);
            bag.AddRange(styles);
            if (bag[^1] == Current) (bag[0], bag[^1]) = (bag[^1], bag[0]);
        }
        Current = bag[^1];
        bag.RemoveAt(bag.Count - 1);
        return Current;
    }
}
