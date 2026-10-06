namespace Stripes;

// A screen saver has no console, so with STRIPES_LOG=1 it appends to %TEMP%\Stripes.log.
static class Log
{
    static readonly string? path =
        Environment.GetEnvironmentVariable("STRIPES_LOG") == "1" ? Path.Combine(Path.GetTempPath(), "Stripes.log") : null;

    public static void Info(string message)
    {
        if (path is null) return;
        try
        {
            File.AppendAllText(path, $"{DateTime.Now:HH:mm:ss.fff} [{Environment.ProcessId}] {message}{Environment.NewLine}");
        }
        catch (IOException)
        {
        }
    }
}
