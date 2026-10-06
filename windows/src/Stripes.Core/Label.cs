namespace Stripes;

// The "location and years" caption: what it says and how opaque it is at a given frame.
// A port of the label part of draw() and drawLabel() in macos/StripesView.swift.
public readonly record struct Label(string Text, int Year, double Alpha, int Corner)
{
    // Corners, clockwise from the first: 0 bottom-left, 1 top-left, 2 top-right, 3 bottom-right.
    public const int BottomLeft = 0, TopLeft = 1, TopRight = 2, BottomRight = 3;

    public static Label For(FrameState f)
    {
        var loc = f.Location;
        var n = loc.YearCount;
        int year;
        double alpha;
        if (f.Building)
        {
            // The year follows the leading edge of styles that reveal left to right; the
            // others show the last year from the start.
            var lead = f.StyleIn switch
            {
                DrawStyle.Sweep => f.P * n,
                DrawStyle.Rise or DrawStyle.Drop or DrawStyle.Flip => f.P * (n + Painter.Wave(f.StyleIn, n)),
                _ => n,
            };
            year = loc.FirstYear + Math.Max(0, Math.Min(n, (int)Math.Ceiling(lead)) - 1);
            alpha = 1;
        }
        else
        {
            year = loc.LastYear;
            alpha = 1 - Painter.Smooth(f.E);
        }
        return new Label($"{loc.Name}  {loc.FirstYear}–{year}", year, alpha, f.Corner);
    }

    // Font size for a view, so the label shrinks with the preview: the chosen size on a full
    // screen, scaled by the view's share of the screen's height, and never below 10.
    public static double Size(double labelSize, double viewHeight, double screenHeight) =>
        Math.Max(10, labelSize * viewHeight / screenHeight);

    // Top-left corner of the text box, top-down: a margin of 1.5 × size from two edges.
    public static (double X, double Y) Position(int corner, double size, double boxWidth, double boxHeight, double width, double height)
    {
        var margin = size * 1.5;
        var left = margin;
        var right = width - margin - boxWidth;
        var top = margin;
        var bottom = height - margin - boxHeight;
        return corner switch
        {
            BottomLeft => (left, bottom),
            TopLeft => (left, top),
            TopRight => (right, top),
            _ => (right, bottom),
        };
    }
}
