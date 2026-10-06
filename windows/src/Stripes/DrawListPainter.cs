using System.Numerics;
using Vortice.Direct2D1;
using Vortice.Mathematics;

namespace Stripes;

// Draws a DrawList with Direct2D, into a window or an offscreen bitmap. The only place that
// converts the bottom-up coordinates of SPEC.md to Direct2D's top-down ones.
static class DrawListPainter
{
    // Call between BeginDraw and EndDraw. The brush is reused for every fill.
    public static void Draw(ID2D1RenderTarget rt, ID2D1Factory factory, ID2D1SolidColorBrush brush, DrawList list)
    {
        var h = (float)list.Height;
        rt.Clear(new Color4(0, 0, 0, 1));

        foreach (var c in list.Commands)
        {
            switch (c.Kind)
            {
                case DrawKind.Rect:
                    brush.Color = new Color4(c.R, c.G, c.B, c.A);
                    rt.AntialiasMode = AntialiasMode.Aliased;
                    rt.FillRectangle(Rect.FromLTRB((float)c.X0, h - (float)c.Y1, (float)c.X1, h - (float)c.Y0), brush);
                    break;

                case DrawKind.Quad:
                {
                    brush.Color = new Color4(c.R, c.G, c.B, c.A);
                    rt.AntialiasMode = AntialiasMode.PerPrimitive;
                    using var quad = factory.CreatePathGeometry();
                    using (var sink = quad.Open())
                    {
                        sink.BeginFigure(new Vector2((float)c.X0, h - (float)c.Y0), FigureBegin.Filled);
                        sink.AddLine(new Vector2((float)c.X1, h - (float)c.Y1));
                        sink.AddLine(new Vector2((float)c.X2, h - (float)c.Y2));
                        sink.AddLine(new Vector2((float)c.X3, h - (float)c.Y3));
                        sink.EndFigure(FigureEnd.Closed);
                        sink.Close();
                    }
                    rt.FillGeometry(quad, brush);
                    break;
                }

                case DrawKind.PushCircleClip:
                {
                    var r = (float)c.X1;
                    using var circle = factory.CreateEllipseGeometry(new Ellipse(new Vector2((float)c.X0, h - (float)c.Y0), r, r));
                    rt.PushLayer(new LayerParameters
                    {
                        ContentBounds = new Rect(float.MinValue / 2, float.MinValue / 2, float.MaxValue, float.MaxValue),
                        GeometricMask = circle,
                        MaskAntialiasMode = AntialiasMode.PerPrimitive,
                        MaskTransform = Matrix3x2.Identity,
                        Opacity = 1,
                    }, null);
                    break;
                }

                case DrawKind.PopClip:
                    rt.PopLayer();
                    break;
            }
        }

    }
}
