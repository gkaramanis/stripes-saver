using System.Numerics;
using Vortice.Direct2D1;
using Vortice.DCommon;
using Vortice.Direct2D1.Effects;
using Vortice.DirectWrite;
using Vortice.DXGI;
using Vortice.Mathematics;

namespace Stripes;

// Draws the location and years in one window: the chosen font at medium weight, white at 75%
// opacity, over a soft black shadow at 50% opacity with no offset (SPEC.md, Label).
sealed class LabelPainter : IDisposable
{
    readonly IDWriteFactory factory;
    readonly IDWriteTextFormat format;
    readonly float size;

    // Device resources, rebuilt when the render target is.
    ID2D1SolidColorBrush? brush;
    Shadow? shadow;
    ID2D1Bitmap? shadowSource;

    // The text whose layout and shadow source are cached; only the year changes, a few times a second at most.
    string? text;
    IDWriteTextLayout? layout;
    int pad;

    // size is in pixels: the label size in points, scaled for the preview and the monitor's DPI.
    public LabelPainter(IDWriteFactory factory, string family, float size)
    {
        this.factory = factory;
        this.size = size;
        format = factory.CreateTextFormat(family, FontWeight.Medium, Vortice.DirectWrite.FontStyle.Normal, FontStretch.Normal, size);
        format.WordWrapping = WordWrapping.NoWrap;
    }

    public void Draw(ID2D1RenderTarget target, Label label, float width, float height)
    {
        if (label.Alpha <= 0) return;

        if (label.Text != text)
        {
            layout?.Dispose();
            layout = factory.CreateTextLayout(label.Text, format, float.MaxValue, float.MaxValue);
            text = label.Text;
            shadowSource?.Dispose();
            shadowSource = null;
        }

        var metrics = layout!.Metrics;
        var (x, y) = Label.Position(label.Corner, size, metrics.WidthIncludingTrailingWhitespace, metrics.Height, width, height);
        var origin = new Vector2((float)x, (float)y);

        brush ??= target.CreateSolidColorBrush(new Color4(1, 1, 1, 1));
        target.TextAntialiasMode = Vortice.Direct2D1.TextAntialiasMode.Grayscale;

        // NSShadow's blur radius is size/4; a Gaussian with half that as its standard deviation looks alike.
        var sigma = size / 8;
        using var context = target.QueryInterface<ID2D1DeviceContext>();
        if (shadowSource is null)
        {
            shadowSource = RenderShadowSource(target, metrics, sigma);
            shadow ??= new Shadow(context);
            shadow.SetInput(0, shadowSource, true);
            shadow.BlurStandardDeviation = sigma;
        }

        // The shadow takes its opacity from the text, which is 75% of the label's alpha.
        var textAlpha = (float)(0.75 * label.Alpha);
        shadow!.Color = new Vector4(0, 0, 0, 0.5f * textAlpha);
        var shadowOrigin = origin - new Vector2(pad, pad);
        context.DrawImage(shadow, shadowOrigin, InterpolationMode.Linear, CompositeMode.SourceOver);

        brush.Color = new Color4(1, 1, 1, textAlpha);
        target.DrawTextLayout(origin, layout, brush, DrawTextOptions.None);
    }

    // The text drawn opaque into its own bitmap, with room for the blur to spread. A compatible
    // render target's bitmap stays bound as its target, which Direct2D won't take as an effect
    // input, so the text is copied into a plain bitmap.
    ID2D1Bitmap RenderShadowSource(ID2D1RenderTarget target, TextMetrics metrics, float sigma)
    {
        pad = (int)Math.Ceiling(3 * sigma);
        var pixels = new SizeI(
            (int)Math.Ceiling(metrics.WidthIncludingTrailingWhitespace) + 2 * pad,
            (int)Math.Ceiling(metrics.Height) + 2 * pad);

        // Premultiplied alpha: the window's target ignores alpha, but the shadow is made from it.
        var format = new PixelFormat(Format.B8G8R8A8_UNorm, Vortice.DCommon.AlphaMode.Premultiplied);
        using var scratch = target.CreateCompatibleRenderTarget(new Size(pixels.Width, pixels.Height), pixels, format, CompatibleRenderTargetOptions.None);
        scratch.BeginDraw();
        scratch.Clear(new Color4(0, 0, 0, 0));
        scratch.TextAntialiasMode = Vortice.Direct2D1.TextAntialiasMode.Grayscale;
        brush!.Color = new Color4(1, 1, 1, 1);
        scratch.DrawTextLayout(new Vector2(pad, pad), layout!, brush, DrawTextOptions.None);
        scratch.EndDraw();

        var bitmap = target.CreateBitmap(pixels, new BitmapProperties(format));
        bitmap.CopyFromRenderTarget(scratch);
        return bitmap;
    }

    // Called when the render target is lost or replaced.
    public void ReleaseDevice()
    {
        shadow?.Dispose();
        shadowSource?.Dispose();
        brush?.Dispose();
        shadow = null;
        shadowSource = null;
        brush = null;
    }

    public void Dispose()
    {
        ReleaseDevice();
        layout?.Dispose();
        format.Dispose();
    }

    // SPEC.md, Options: systemMono and system stand for the platform's mono and UI fonts; any
    // other name is a font family, falling back to the mono font if it isn't installed.
    public static string ResolveFamily(IDWriteFactory factory, string labelFont)
    {
        using var fonts = factory.GetSystemFontCollection(false);
        bool Installed(string family) => fonts.FindFamilyName(family, out _);
        string Mono() => Installed("Cascadia Mono") ? "Cascadia Mono" : "Consolas";

        return labelFont switch
        {
            SaverSettings.SystemMono => Mono(),
            SaverSettings.System => "Segoe UI",
            _ when Installed(labelFont) => labelFont,
            _ => Mono(),
        };
    }
}
