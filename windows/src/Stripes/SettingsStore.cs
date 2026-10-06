using Microsoft.Win32;

namespace Stripes;

// The options in HKCU\Software\Stripes, under the macOS keys (see SettingsCodec).
static class SettingsStore
{
    const string KeyPath = @"Software\Stripes";

    public static SaverSettings Load()
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(KeyPath);
            return SettingsCodec.Read(name => key?.GetValue(name));
        }
        catch (Exception e) when (e is System.Security.SecurityException or IOException or UnauthorizedAccessException)
        {
            Log.Info($"reading settings failed: {e.Message}");
            return new SaverSettings();
        }
    }

    public static void Save(SaverSettings settings)
    {
        using var key = Registry.CurrentUser.CreateSubKey(KeyPath);
        foreach (var (name, value) in SettingsCodec.Write(settings))
        {
            var kind = value switch
            {
                int => RegistryValueKind.DWord,
                string[] => RegistryValueKind.MultiString,
                _ => RegistryValueKind.String,
            };
            key.SetValue(name, value, kind);
        }
    }
}
