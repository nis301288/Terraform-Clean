using Prometheus;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseOpenTelemetryPrometheusScrapingEndpoint();

app.UseRouting();

// Prometheus middleware to collect default HTTP metrics
app.UseHttpMetrics();

app.UseAuthorization();

// Map Razor Pages
app.MapRazorPages();

// Expose Prometheus metrics endpoint at /metrics
app.MapMetrics();

app.Run();

app.UseMetricServer(); 