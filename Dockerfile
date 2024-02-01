# Use a specific version of the SDK
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build

# Set the working directory
WORKDIR /src

# Copy and restore dependencies
COPY ["dproj.csproj", "."]
RUN dotnet restore "./dproj.csproj"

# Copy the entire project and build
COPY . .
RUN dotnet build "./dproj.csproj" -c Release -o /app/build

# Create the publish image
FROM build AS publish

# Publish the application
RUN dotnet publish "./dproj.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Create the final image
FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS final

# Set the working directory
WORKDIR /app

# Copy the published output
COPY --from=publish /app/publish .

# Install the ASP.NET Core HTTPS development certificate
RUN apt-get update \
    && apt-get install -y liblttng-ust0 \
    && dotnet dev-certs https --trust

# Expose ports
EXPOSE 80
EXPOSE 443

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl --fail http://localhost/ || exit 1

# Entrypoint
ENTRYPOINT ["dotnet", "dproj.dll"]

# Clean up intermediate build artifacts
RUN rm -rf /src
