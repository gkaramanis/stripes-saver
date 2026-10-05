namespace Stripes;

static class Program
{
    // Entry point until the screen saver host arrives (milestone M2). Loading the data here
    // means a Native AOT publish exercises the embedded resource and JSON source generation.
    static int Main()
    {
        var data = StripesData.LoadEmbedded();
        return data.Locations.Count > 0 ? 0 : 1;
    }
}
