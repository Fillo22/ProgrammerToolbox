#!/bin/bash

read -p "Inserisci il nome del progetto: " project_name
read -p "Inserisci il namespace del progetto: " project_namespace
read -p "Inserisci la chiave di strumentazione di Application Insights: " app_insights_instrumentation_key

# Crea la directory principale del progetto
mkdir $project_name
cd $project_name

# Crea la struttura a strati del progetto
mkdir src
cd src

# Presentation Layer (Web API)
mkdir $project_name.Presentation
cd $project_name.Presentation
dotnet new webapi
cd ..

# Application Layer
mkdir $project_name.Application
cd $project_name.Application
dotnet new classlib
dotnet add reference ../$project_name.Presentation
cd ..
mkdir $project_name.Application/Interfaces
mkdir $project_name.Application/Services

# Service Layer
mkdir $project_name.Service
cd $project_name.Service
dotnet new classlib
dotnet add reference ../$project_name.Application
cd ..
mkdir $project_name.Service/Interfaces
mkdir $project_name.Service/Services

# Data Access Layer
mkdir $project_name.DataAccess
cd $project_name.DataAccess
dotnet new classlib
dotnet add reference ../$project_name.Application
cd ..

# Infrastructure Layer
mkdir $project_name.Infrastructure
cd $project_name.Infrastructure
dotnet new classlib
dotnet add reference ../$project_name.Application
cd ..

# Test Project
mkdir $project_name.Tests
cd $project_name.Tests
dotnet new xunit
dotnet add reference ../$project_name.Presentation
dotnet add reference ../$project_name.Application
dotnet add reference ../$project_name.Service
dotnet add reference ../$project_name.DataAccess
dotnet add reference ../$project_name.Infrastructure
cd ..

# Torna alla directory principale del progetto
cd ..

# Aggiungi il progetto principale e collega i layer
dotnet new sln
dotnet sln add src/$project_name.Presentation/$project_name.Presentation.csproj
dotnet sln add src/$project_name.Application/$project_name.Application.csproj
dotnet sln add src/$project_name.Service/$project_name.Service.csproj
dotnet sln add src/$project_name.DataAccess/$project_name.DataAccess.csproj
dotnet sln add src/$project_name.Infrastructure/$project_name.Infrastructure.csproj
dotnet sln add src/$project_name.Tests/$project_name.Tests.csproj

# Aggiorna il namespace del progetto
find . -type f -name '*.cs' -exec sed -i "s/MyNamespace/$project_namespace/g" {} +

# Aggiungi Serilog per Application Insights
cd src/$project_name.Presentation
dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.ApplicationInsights

# Crea il file Startup.cs
cat << EOF > Startup.cs
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Serilog;
using Serilog.Events;
using $project_namespace.Presentation.Options;

namespace $project_namespace.Presentation
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            services.Configure<ApplicationInsightsOptions>(Configuration.GetSection("ApplicationInsights"));
            var appInsightsOptions = Configuration.GetSection("ApplicationInsights").Get<ApplicationInsightsOptions>();
            services.AddControllers();
            services.AddLogging(loggingBuilder =>
            {
                loggingBuilder.ClearProviders();
                loggingBuilder.AddSerilog(new LoggerConfiguration()
                    .MinimumLevel.Override("Microsoft", LogEventLevel.Information)
                    .Enrich.FromLogContext()
                    .WriteTo.ApplicationInsightsTraces(appInsightsOptions.InstrumentationKey)
                    .CreateLogger());
            });
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            app.UseSerilogRequestLogging();
            app.UseRouting();
            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}
EOF
cd ..

# Aggiungi il file appsettings.json di default
cd src/$project_name.Presentation
cat << EOF > appsettings.json
{
  "ApplicationInsights": {
    "InstrumentationKey": "$app_insights_instrumentation_key"
  }
}
EOF
cd ..

# Aggiungi la configurazione Serilog in Program.cs
cd src/$project_name.Presentation
cat << EOF > Program.cs
using Microsoft.Extensions.Hosting;
using Serilog;
using $project_namespace.Presentation.Options;

namespace $project_namespace.Presentation
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var host = CreateHostBuilder(args).Build();
            host.Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureLogging((hostingContext, logging) =>
                {
                    logging.ClearProviders();
                    var appInsightsOptions = hostingContext.Configuration.GetSection("ApplicationInsights").Get<ApplicationInsightsOptions>();
                    logging.AddSerilog(new LoggerConfiguration()
                        .MinimumLevel.Override("Microsoft", LogEventLevel.Information)
                        .Enrich.FromLogContext()
                        .WriteTo.ApplicationInsightsTraces(appInsightsOptions.InstrumentationKey)
                        .CreateLogger());
                })
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                });
    }
}
EOF
cd ..

# Torna alla directory principale del progetto
cd ..

# Inizializza un repository Git
git init

# Esegui il primo commit
git add .
git commit -m "First commit"

echo "Struttura del progetto creata con successo!"
