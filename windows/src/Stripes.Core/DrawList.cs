namespace Stripes;

public enum DrawKind
{
    // An axis-aligned rectangle, drawn without antialiasing so neighbouring stripes meet exactly.
    Rect,

    // A filled quadrilateral, antialiased (Blinds).
    Quad,

    // Clip everything until PopClip to a circle (Iris).
    PushCircleClip,
    PopClip,
}

// One drawing command. Coordinates follow SPEC.md and AppKit, with the origin at the
// bottom-left and y pointing up; the renderer flips them for Direct2D.
//   Rect:           (X0, Y0) bottom-left corner, (X1, Y1) top-right corner
//   Quad:           four corners in order
//   PushCircleClip: centre (X0, Y0), radius X1
public readonly record struct DrawCommand(
    DrawKind Kind,
    double X0, double Y0, double X1, double Y1,
    double X2, double Y2, double X3, double Y3,
    float R, float G, float B, float A);

// The commands for one frame, in painting order, over a black background.
public sealed class DrawList
{
    readonly List<DrawCommand> commands = [];

    public double Width { get; private set; }
    public double Height { get; private set; }
    public IReadOnlyList<DrawCommand> Commands => commands;

    public void Reset(double width, double height)
    {
        Width = width;
        Height = height;
        commands.Clear();
    }

    // Like fill() in macos/StripesView.swift: nothing is drawn if invisible or empty.
    public void FillRect(double x, double y, double width, double height, Colour colour, double alpha)
    {
        if (alpha <= 0 || width <= 0 || height <= 0) return;
        commands.Add(new(DrawKind.Rect, x, y, x + width, y + height, 0, 0, 0, 0, colour.R, colour.G, colour.B, (float)alpha));
    }

    public void FillQuad(double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3, Colour colour) =>
        commands.Add(new(DrawKind.Quad, x0, y0, x1, y1, x2, y2, x3, y3, colour.R, colour.G, colour.B, 1));

    public void PushCircleClip(double cx, double cy, double radius) =>
        commands.Add(new(DrawKind.PushCircleClip, cx, cy, radius, 0, 0, 0, 0, 0, 0, 0, 0, 0));

    public void PopClip() =>
        commands.Add(new(DrawKind.PopClip, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
}

// A colour with components from 0 to 1, so it can be blended toward black.
public readonly record struct Colour(float R, float G, float B)
{
    public static readonly Colour Black = new(0, 0, 0);

    public static Colour From(Rgb c) => new(c.R / 255f, c.G / 255f, c.B / 255f);

    // NSColor.blended(withFraction:of: .black): each component moves toward 0 by the fraction.
    public Colour Darkened(double fraction)
    {
        var k = (float)(1 - fraction);
        return new(R * k, G * k, B * k);
    }
}
