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

        try
        {
            var data = StripesData.LoadEmbedded();
            if (parsed.Mode == SaverMode.Configure)
            {
                if (!OperatingSystem.IsWindowsVersionAtLeast(10, 0, 14393)) return 1;
                OptionsDialog.Show(parsed.Window, data);
                return 0;
            }
            return SaverHost.Run(parsed, data, SettingsStore.Load());
        }
        catch (Exception e)
        {
            Log.Info(e.ToString());
            throw;
        }
    }
}
