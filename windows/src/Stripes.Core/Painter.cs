namespace Stripes;

// Turns a frame into drawing commands. A port of draw(), paint() and drawBlinds() in
// macos/StripesView.swift; SPEC.md, Drawing describes the same formulas.
public static class Painter
{
    public const int BlindSlats = 20;

    public static void Frame(DrawList list, FrameState f, double width, double height)
    {
        list.Reset(width, height);
        if (f.Building)
        {
            Paint(list, f.Location, f.StyleIn, f.P, erase: false, f.Order, f.TileOrder);
        }
        else
        {
            // The build out replays its style in black over the finished picture.
            Paint(list, f.Location, DrawStyle.Fade, 1, erase: false, f.Order, f.TileOrder);
            Paint(list, f.Location, f.StyleOut, f.E, erase: true, f.Order, f.TileOrder);
        }
    }

    // Draws a location at progress p through a style. When erasing, the same motion paints black.
    public static void Paint(DrawList list, Location loc, DrawStyle style, double p, bool erase, int[] order, int[] tileOrder)
    {
        var n = (double)loc.YearCount;
        var h = list.Height;
        var width = list.Width / n;
        var wave = Wave(style, n);
        Colour ColourOf(int i) => erase ? Colour.Black : Colour.From(loc.Colours[i]);

        // Progress of stripe x through its own part of a left-to-right wave.
        double WaveAt(double x) => Clamp((p * (n + wave) - x) / wave);

        if (style == DrawStyle.Blinds)
        {
            PaintBlinds(list, loc.YearCount, p, ColourOf);
            return;
        }

        if (style == DrawStyle.Iris)
        {
            var r = Smooth(p) * Math.Sqrt(list.Width * list.Width + h * h) / 2;
            list.PushCircleClip(list.Width / 2, h / 2, r);
        }

        for (var i = 0; i < loc.YearCount; i++)
        {
            var x = (double)i;
            var colour = ColourOf(i);

            // Round edges to whole pixels so neighbouring stripes don't leave seams.
            var x0 = Round(i * width);
            var x1 = Round((i + 1) * width);

            switch (style)
            {
                case DrawStyle.Sweep:
                    list.FillRect(x0, 0, x1 - x0, h, colour, Clamp(p * n - x));
                    break;
                case DrawStyle.Rise:
                    list.FillRect(x0, 0, x1 - x0, Round(h * Smooth(WaveAt(x))), colour, 1);
                    break;
                case DrawStyle.Scatter:
                    list.FillRect(x0, 0, x1 - x0, h, colour, Clamp((p * (n + wave) - order[i]) / wave));
                    break;
                case DrawStyle.Fade:
                    list.FillRect(x0, 0, x1 - x0, h, colour, Smooth(p));
                    break;
                case DrawStyle.Iris:
                    list.FillRect(x0, 0, x1 - x0, h, colour, p > 0 ? 1 : 0);
                    break;
                case DrawStyle.Drop:
                {
                    var q = WaveAt(x);
                    if (q <= 0) continue;
                    list.FillRect(x0, Round(h * (1 - DropFall(q))), x1 - x0, h, colour, 1);
                    break;
                }
                case DrawStyle.Flip:
                {
                    // The stripe turns about its centre line, darker while it is edge-on.
                    var q = Smooth(WaveAt(x));
                    var w = (x1 - x0) * q;
                    list.FillRect((x0 + x1 - w) / 2, 0, w, h, colour.Darkened(0.6 * (1 - q)), 1);
                    break;
                }
                case DrawStyle.Mosaic:
                {
                    var cells = n * Timeline.MosaicRows;
                    var tile = h / Timeline.MosaicRows;
                    for (var row = 0; row < Timeline.MosaicRows; row++)
                    {
                        var rank = (double)tileOrder[i * Timeline.MosaicRows + row];
                        var a = Clamp((p * (cells + cells / 20) - rank) / (cells / 20));
                        var y0 = Round(row * tile);
                        var y1 = Round((row + 1) * tile);
                        list.FillRect(x0, y0, x1 - x0, y1 - y0, colour, a);
                    }
                    break;
                }
            }
        }

        if (style == DrawStyle.Iris) list.PopClip();
    }

    // Keynote's Blinds: vertical slats swing from edge-on to face the viewer, in perspective.
    // Rotation about a vertical axis keeps vertical lines vertical, so each stripe's part
    // of a slat projects to a quadrilateral with vertical sides.
    static void PaintBlinds(DrawList list, int n, double p, Func<int, Colour> colourOf)
    {
        var h = list.Height;
        var slat = list.Width / BlindSlats;
        var stripe = list.Width / n;
        var focal = h;

        for (var k = 0; k < BlindSlats; k++)
        {
            // Each slat turns in 30% of the draw-in time; start times spread over the rest.
            var q = Smooth(Clamp((p - 0.7 * k / (BlindSlats - 1)) / 0.3));
            if (q <= 0) continue;
            var angle = (1 - q) * Math.PI / 2;
            var cosA = Math.Cos(angle);
            var sinA = Math.Sin(angle);
            var left = k * slat;
            var centre = left + slat / 2;

            // Screen x and half-height of the slat's vertical line that sits at x when flat.
            (double X, double Half) Project(double x)
            {
                var u = x - centre;
                var scale = focal / (focal + u * sinA);
                return (centre + u * cosA * scale, h / 2 * scale);
            }

            var first = Math.Max(0, (int)(left / stripe));
            var last = Math.Min(n - 1, (int)((left + slat) / stripe));
            for (var i = first; i <= last; i++)
            {
                var x0 = Math.Max(left, i * stripe);
                var x1 = Math.Min(left + slat, (i + 1) * stripe);
                if (x1 <= x0) continue;
                var a = Project(x0);
                var b = Project(x1);

                // Overlap the next quad by half a pixel so antialiasing leaves no seams.
                var bx = b.X + 0.5;
                list.FillQuad(
                    a.X, h / 2 - a.Half,
                    bx, h / 2 - b.Half,
                    bx, h / 2 + b.Half,
                    a.X, h / 2 + a.Half,
                    colourOf(i).Darkened(0.6 * (1 - q)));
            }
        }
    }

    // How many stripes are in motion at once, for the styles that move across the screen.
    public static double Wave(DrawStyle style, double n) => style switch
    {
        DrawStyle.Rise => Math.Max(1, n / 4),
        DrawStyle.Drop => Math.Max(1, n / 14),
        DrawStyle.Flip => Math.Max(1, n / 8),
        _ => Math.Max(1, n / 20),
    };

    // Position of a dropped stripe: a fall under gravity, then two quick, low bounces
    // whose durations follow from their heights.
    public static double DropFall(double t)
    {
        const double h1 = 0.06, h2 = 0.015;
        var b1 = 2 * Math.Sqrt(h1);
        var b2 = 2 * Math.Sqrt(h2);
        var u = t * (1 + b1 + b2);
        if (u < 1) return u * u;
        u -= 1;
        if (u < b1) { var v = u - b1 / 2; return 1 - (h1 - v * v); }
        u -= b1;
        if (u < b2) { var v = u - b2 / 2; return 1 - (h2 - v * v); }
        return 1;
    }

    public static double Clamp(double v) => Math.Min(1, Math.Max(0, v));

    public static double Smooth(double v) => v * v * (3 - 2 * v);

    // Swift's rounded() rounds halves away from zero; Math.Round would round them to even.
    public static double Round(double v) => Math.Round(v, MidpointRounding.AwayFromZero);
}
