namespace Stripes.Tests;

public class ScreenSaverArgsTests
{
    static ScreenSaverArgs Parse(params string[] args)
    {
        Assert.True(ScreenSaverArgs.TryParse(args, out var result));
        return result;
    }

    [Fact]
    public void No_arguments_means_configure() =>
        Assert.Equal(new ScreenSaverArgs(SaverMode.Configure, 0), Parse());

    [Theory]
    [InlineData("/s")]
    [InlineData("/S")]
    [InlineData("-s")]
    [InlineData(" /s ")]
    public void Show(string arg) => Assert.Equal(SaverMode.Show, Parse(arg).Mode);

    [Theory]
    [InlineData("/p", "1234")]
    [InlineData("/P", "1234")]
    [InlineData("-p", "1234")]
    [InlineData("/p:1234", null)]
    [InlineData("/p1234", null)]
    [InlineData("/l", "1234")]
    [InlineData("/p", "0x4D2")]
    public void Preview(string arg, string? value)
    {
        var args = value is null ? new[] { arg } : new[] { arg, value };
        Assert.Equal(new ScreenSaverArgs(SaverMode.Preview, 1234), Parse(args));
    }

    [Theory]
    [InlineData("/c", 0)]
    [InlineData("/c:5678", 5678)]
    [InlineData("/C:5678", 5678)]
    [InlineData("-c", 0)]
    public void Configure(string arg, long window) =>
        Assert.Equal(new ScreenSaverArgs(SaverMode.Configure, (nint)window), Parse(arg));

    [Theory]
    [InlineData("/p")]           // no window
    [InlineData("/p", "0")]      // null window
    [InlineData("/p", "abc")]
    [InlineData("/c:abc")]
    [InlineData("/x")]
    [InlineData("/")]
    public void Rejects(params string[] args) =>
        Assert.False(ScreenSaverArgs.TryParse(args, out _));
}
