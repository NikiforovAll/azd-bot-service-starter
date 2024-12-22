using Azure.Identity;
using EchoBot;
using EchoBot.Bots;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Integration.AspNet.Core;
using Microsoft.Bot.Connector.Authentication;
using Microsoft.Extensions.Azure;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApplicationInsightsTelemetry(builder.Configuration);

var vaultUri = builder.Configuration["AZURE_KEY_VAULT_ENDPOINT"];
if (!string.IsNullOrWhiteSpace(vaultUri))
{
    builder.Configuration.AddAzureKeyVault(new Uri(vaultUri), new DefaultAzureCredential());
}

builder.Services.AddAzureClients(clientBuilder =>
{
    DefaultAzureCredential credential = new();
    clientBuilder.UseCredential(credential);
});

builder.Services.AddHealthChecks();

builder
    .Services.AddHttpClient()
    .AddControllers()
    .AddNewtonsoftJson(options =>
    {
        options.SerializerSettings.MaxDepth = HttpHelper.BotMessageSerializerSettings.MaxDepth;
    });

// Create the Bot Framework Authentication to be used with the Bot Adapter.
builder.Services.AddSingleton<
    BotFrameworkAuthentication,
    ConfigurationBotFrameworkAuthentication
>();

// Create the Bot Adapter with error handling enabled.
builder.Services.AddSingleton<IBotFrameworkHttpAdapter, AdapterWithErrorHandler>();

builder.Services.AddTransient<IBot, EchoBotHandler>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.UseDefaultFiles().UseStaticFiles().UseWebSockets().UseRouting().UseAuthorization();

app.MapPost(
    "/api/messages",
    async (IBotFrameworkHttpAdapter adapter, IBot bot, HttpRequest req, HttpResponse res) =>
    {
        await adapter.ProcessAsync(req, res, bot);
    }
);
app.MapHealthChecks("/health");

app.UseHttpsRedirection();

app.Run();
