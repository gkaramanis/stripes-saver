using Vortice.DCommon;
using Vortice.Direct2D1;
using Vortice.DXGI;
using Vortice.Mathematics;

namespace Stripes;

// Draws frames into one window: a Direct2D render target for the window, recreated if the
// device is lost.
sealed class StripesRenderer : IDisposable
{
    readonly ID2D1Factory factory;
    readonly nint hwnd;
    readonly LabelPainter? labelPainter;
    ID2D1HwndRenderTarget? target;
    ID2D1SolidColorBrush? brush;
    int width, height;

    public StripesRenderer(ID2D1Factory factory, nint hwnd, int width, int height, LabelPainter? labelPainter)
    {
        this.factory = factory;
        this.labelPainter = labelPainter;
        this.hwnd = hwnd;
        this.width = width;
        this.height = height;
    }

    public void Render(DrawList list, Label? label)
    {
        EnsureTarget();
        var rt = target!;
        rt.BeginDraw();
        DrawListPainter.Draw(rt, factory, brush!, list);

        if (label is { } l) labelPainter?.Draw(rt, l, (float)list.Width, (float)list.Height);

        var result = rt.EndDraw();
        if (result.Failure) Log.Info($"EndDraw failed: 0x{result.Code:X8}");
        if (result.Code == unchecked((int)0x8899000C))  // D2DERR_RECREATE_TARGET
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
        labelPainter?.ReleaseDevice();
        brush?.Dispose();
        target?.Dispose();
        brush = null;
        target = null;
    }

    public void Dispose()
    {
        ReleaseTarget();
        labelPainter?.Dispose();
    }
}
