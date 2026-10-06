namespace Stripes;

// Converts SaverSettings to and from stored values: strings (REG_SZ), ints (REG_DWORD) and
// string arrays (REG_MULTI_SZ), under the macOS keys. Missing or unusable values fall back to
// the defaults, and numbers are clamped to their ranges, so a hand-edited registry can't break
// the saver.
public static class SettingsCodec
{
    public const string Style = "style";
    public const string ExitStyle = "exitStyle";
    public const string DrawIn = "drawIn";
    public const string ShowLabel = "showLabel";
    public const string LabelFont = "labelFont";
    public const string LabelSize = "labelSize";
    public const string Locations = "locations";

    public static SaverSettings Read(Func<string, object?> value)
    {
        var d = new SaverSettings();
        return new SaverSettings
        {
            Style = value(Style) is string s && DrawStyles.TryParseKey(s, out var style) ? style : d.Style,
            ExitStyle = value(ExitStyle) is string e && DrawStyles.TryParseKey(e, out var exit) ? exit : d.ExitStyle,
            DrawIn = value(DrawIn) is int i ? Math.Clamp(i, SaverSettings.MinDrawIn, SaverSettings.MaxDrawIn) : d.DrawIn,
            ShowLabel = value(ShowLabel) is int b ? b != 0 : d.ShowLabel,
            LabelFont = value(LabelFont) is string { Length: > 0 } f ? f : d.LabelFont,
            LabelSize = value(LabelSize) is int z ? Math.Clamp(z, SaverSettings.MinLabelSize, SaverSettings.MaxLabelSize) : d.LabelSize,
            Locations = value(Locations) is string[] names && names.Any(n => n.Length > 0)
                ? names.Where(n => n.Length > 0).ToArray()
                : d.Locations,
        };
    }

    public static IEnumerable<(string Name, object Value)> Write(SaverSettings s) =>
    [
        (Style, s.Style.Key()),
        (ExitStyle, s.ExitStyle.Key()),
        (DrawIn, (int)Math.Round(s.DrawIn)),
        (ShowLabel, s.ShowLabel ? 1 : 0),
        (LabelFont, s.LabelFont),
        (LabelSize, s.LabelSize),
        (Locations, s.Locations.ToArray()),
    ];
}
