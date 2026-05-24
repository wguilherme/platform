using System.Text.Json.Serialization;

var builder = WebApplication.CreateSlimBuilder(args);
builder.Services.ConfigureHttpJsonOptions(o =>
    o.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonContext.Default));

var app = builder.Build();

app.MapGet("/", () => new HelloResponse(
    "Hello from C#!",
    Environment.GetEnvironmentVariable("APP_VERSION") ?? "dev",
    System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription,
    System.Net.Dns.GetHostName()
));

app.MapGet("/health", () => "ok");

app.Run($"http://0.0.0.0:{Environment.GetEnvironmentVariable("PORT") ?? "8080"}");

record HelloResponse(string Message, string Version, string Runtime, string Hostname);

[JsonSerializable(typeof(HelloResponse))]
internal partial class AppJsonContext : JsonSerializerContext { }
