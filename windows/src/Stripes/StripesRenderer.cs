using System.Numerics;
using Vortice.DCommon;
using Vortice.Direct2D1;
using Vortice.DXGI;
using Vortice.Mathematics;

namespace Stripes;

// Draws a DrawList into one window with Direct2D. The only place that converts the
// bottom-up coordinates of SPEC.md to Direct2D's top-down ones.
sealed class StripesRenderer : IDisposable
{
    readonly ID2D1Factory factory;
    readonly nint hwnd;
    ID2D1HwndRenderTarget? target;
    ID2D1SolidColorBrush? brush;
    int width, height;

    public StripesRenderer(ID2D1Factory factory, nint hwnd, int width, int height)
    {
        this.factory = factory;
        this.hwnd = hwnd;
        this.width = width;
        this.height = height;
    }

    public void Render(DrawList list)
    {
        EnsureTarget();
        var rt = target!;
        var h = (float)list.Height;
        rt.BeginDraw();
        rt.Clear(new Color4(0, 0, 0, 1));

        foreach (var c in list.Commands)
        {
            switch (c.Kind)
            {
                case DrawKind.Rect:
                    brush!.Color = new Color4(c.R, c.G, c.B, c.A);
                    rt.AntialiasMode = AntialiasMode.Aliased;
                    rt.FillRectangle(Rect.FromLTRB((float)c.X0, h - (float)c.Y1, (float)c.X1, h - (float)c.Y0), brush);
                    break;

                case DrawKind.Quad:
                {
                    brush!.Color = new Color4(c.R, c.G, c.B, c.A);
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

        if (rt.EndDraw().Code == unchecked((int)0x8899000C))  // D2DERR_RECREATE_TARGET
        {
            ReleaseTarget();
        }
    }

    void EnsureTarget()
    {
        if (target is not null) return;

        // 96 DPI, so one Direct2D unit is one pixel whatever the monitor's scaling.
        var properties = new RenderTargetProperties(new PixelFormat(Format.B8G8R8A8_UNorm, Vortice.DCommon.AlphaMode.Ignore))
        {
            DpiX = 96,
            DpiY = 96,
        };
        var hwndProperties = new HwndRenderTargetProperties
        {
            Hwnd = hwnd,
            PixelSize = new SizeI(width, height),

            // Frames are paced by the host's clock, so several windows don't each wait for vsync.
            PresentOptions = PresentOptions.Immediately,
        };
        target = factory.CreateHwndRenderTarget(properties, hwndProperties);
        brush = target.CreateSolidColorBrush(new Color4(0, 0, 0, 1));
    }

    void ReleaseTarget()
    {
        brush?.Dispose();
        target?.Dispose();
        brush = null;
        target = null;
    }

    public void Dispose() => ReleaseTarget();
}
