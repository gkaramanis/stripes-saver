using System.Globalization;
using Vortice.DCommon;
using Vortice.Direct2D1;
using Vortice.Mathematics;
using Vortice.WIC;
using D2DPixelFormat = Vortice.DCommon.PixelFormat;
using WicPixelFormat = Vortice.WIC.PixelFormat;

namespace Stripes;

// Renders one build style as PNG frames: the build in, a short hold, the build out. With "in"
// last, it renders the build in and a short hold only. The Windows twin of macos/tools/render,
// with the same arguments, timing and file names, so frames can be compared one to one.
// Usage: render <style> <out-dir> [width height fps seconds [in]] [--seed n]
static class Program
{
    static int Main(string[] argv)
    {
        var args = argv.ToList();
        int? seed = null;
        var s = args.IndexOf("--seed");
        if (s >= 0 && s + 1 < args.Count)
        {
            seed = int.Parse(args[s + 1], CultureInfo.InvariantCulture);
            args.RemoveRange(s, 2);
        }

        if (args.Count < 2 || !DrawStyles.TryParseKey(args[0], out var style) || style == DrawStyle.Random)
        {
            Console.Error.WriteLine("usage: render <style> <out-dir> [width height fps seconds [in]] [--seed n]");
            return 1;
        }
        var outDir = args[1];
        double Arg(int i, double fallback) => args.Count > i ? double.Parse(args[i], CultureInfo.InvariantCulture) : fallback;
        var width = (int)Arg(2, 960);
        var height = (int)Arg(3, 540);
        var fps = Arg(4, 30);
        var build = Arg(5, 3);
        var buildInOnly = args.Count > 6 && args[6] == "in";

        // The saver holds each picture for 15 s; the clip shows one second of it.
        const double shownHold = 1, gap = 0.4;

        var data = StripesData.LoadEmbedded();
        var settings = new SaverSettings { Style = style, ExitStyle = style, DrawIn = build, ShowLabel = false };
        var timeline = new Timeline([data.Global], settings, seed is { } v ? new Random(v) : new Random(), now: 0);

        using var wic = new IWICImagingFactory();
        using var d2d = D2D1.D2D1CreateFactory<ID2D1Factory>();
        using var bitmap = wic.CreateBitmap((uint)width, (uint)height, WicPixelFormat.Format32bppPBGRA, BitmapCreateCacheOption.CacheOnLoad);
        using var target = d2d.CreateWicBitmapRenderTarget(bitmap, new RenderTargetProperties(
            new D2DPixelFormat(Vortice.DXGI.Format.B8G8R8A8_UNorm, AlphaMode.Premultiplied)) { DpiX = 96, DpiY = 96 });
        using var brush = target.CreateSolidColorBrush(new Color4(0, 0, 0, 1));
        var list = new DrawList();

        Directory.CreateDirectory(outDir);
        var total = buildInOnly ? build + 1.5 : build + shownHold + build + gap;
        var frames = (int)Math.Round(total * fps, MidpointRounding.AwayFromZero);
        for (var f = 0; f < frames; f++)
        {
            var t = f / fps;
            var now = t < build + shownHold ? t : t - shownHold + Timeline.Hold;
            Painter.Frame(list, timeline.StateAt(now), width, height);

            target.BeginDraw();
            DrawListPainter.Draw(target, d2d, brush, list);
            target.EndDraw();

            using var stream = wic.CreateStream(Path.Combine(outDir, $"{f:D4}.png"), FileAccess.Write);
            using var encoder = wic.CreateEncoder(ContainerFormat.Png, stream);
            using var frame = encoder.CreateNewFrame(out var props);
            frame.Initialize(props);
            frame.WriteSource(bitmap);
            frame.Commit();
            encoder.Commit();
        }
        Console.WriteLine($"{style.Key()}: {frames} frames");
        return 0;
    }
}
