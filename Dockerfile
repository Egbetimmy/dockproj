#See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["dproj.csproj", "."]
RUN dotnet restore "./././dproj.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "./dproj.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./dproj.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Install the ASP.NET Core HTTPS development certificate
RUN apt-get update \
    && apt-get install -y liblttng-ust0 \
    && dotnet dev-certs https --trust
EXPOSE 80
EXPOSE 443

ENTRYPOINT ["dotnet", "dproj.dll"]
