namespace Stripes;

// In the same order as the macOS DrawStyle. Random picks one of the others for each location.
public enum DrawStyle { Sweep, Rise, Scatter, Fade, Drop, Flip, Blinds, Iris, Mosaic, Random }

public static class DrawStyles
{
    // Every style that draws, which is all but Random.
    public static readonly DrawStyle[] Animated = Enum.GetValues<DrawStyle>().Where(s => s != DrawStyle.Random).ToArray();

    // The stored name, as macOS saves it: "sweep", "rise", ...
    public static string Key(this DrawStyle style) => style.ToString().ToLowerInvariant();

    public static bool TryParseKey(string? key, out DrawStyle style)
    {
        foreach (var s in Enum.GetValues<DrawStyle>())
        {
            if (string.Equals(s.Key(), key, StringComparison.Ordinal))
            {
                style = s;
                return true;
            }
        }
        style = default;
        return false;
    }
}

// The saver's options, with the macOS keys, defaults and ranges (SPEC.md, Options).
public sealed record SaverSettings
{
    public const int MinDrawIn = 5, MaxDrawIn = 60;
    public const int MinLabelSize = 12, MaxLabelSize = 72;

    // Label font names that stand for the system fonts; any other name is a font family.
    public const string SystemMono = "systemMono";
    public const string System = "system";

    public DrawStyle Style { get; init; } = DrawStyle.Sweep;
    public DrawStyle ExitStyle { get; init; } = DrawStyle.Fade;

    // Seconds for the build in, and again for the build out.
    public double DrawIn { get; init; } = 14;
    public bool ShowLabel { get; init; } = true;
    public string LabelFont { get; init; } = SystemMono;

    // Label size in points on the full screen. The preview scales it down with its height.
    public int LabelSize { get; init; } = 24;
    public IReadOnlyList<string> Locations { get; init; } = [StripesData.GlobalName];
}
