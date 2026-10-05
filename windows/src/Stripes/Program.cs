namespace Stripes;

static class Program
{
    static int Main(string[] args)
    {
        if (!ScreenSaverArgs.TryParse(args, out var parsed))
        {
            Log.Info($"unrecognised arguments: {string.Join(' ', args)}");
            return 1;
        }

        // The defaults until the options are stored (milestone M4).
        var settings = new SaverSettings();

        try
        {
            return parsed.Mode == SaverMode.Configure
                ? SaverHost.ShowOptions(parsed.Window)
                : SaverHost.Run(parsed, StripesData.LoadEmbedded(), settings);
        }
        catch (Exception e)
        {
            Log.Info(e.ToString());
            throw;
        }
    }
}
