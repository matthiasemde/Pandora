{
  description = "AgendaV Docker image with Apache + PHP + SQLite";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      backendNetwork = "fluid-calendar-backend";
    in
    {
      name = "fluid-calendar";
      dependencies = {
        networks = {
          ${backendNetwork} = "";
        };
      };
      containers =
        { hostname, getServiceEnvFiles, ... }:
        {
          fluid-calendar-app = {
            image = "eibrahim/fluid-calendar:1.4.0";
            ports = [ "3000:3000" ];
            networks = [
              "traefik"
              backendNetwork
            ];
            extraOptions = [ "--dns=1.1.1.1" ];
            environment = {
              # Database Configuration
              # DATABASE_URL=postgresql://fluid:<password>@fluid-calendar-database:5432/fluid_calendar

              # NextAuth Configuration
              # Use domain in production, localhost for development
              NEXTAUTH_URL = "https://fluid-calendar.emdecloud.de";
              NEXTAUTH_URL_INTERNAL="http://fluid-calendar-app:3000";
              NEXT_PUBLIC_APP_URL = "https://fluid-calendar.emdecloud.de";
              # NEXTAUTH_SECRET="your-secret-key-min-32-chars"
              NEXT_PUBLIC_SITE_URL = "https://fluid-calendar.emdecloud.de";
              HOSTNAME = "0.0.0.0";

              NEXT_PUBLIC_ENABLE_SAAS_FEATURES = "false";

              # RESEND_API_KEY=
              # RESEND_FROM_EMAIL=
            };
            environmentFiles = getServiceEnvFiles "fluid-calendar";
            labels = {
              # 🛡️ Traefik
              "traefik.enable" = "true";
              "traefik.http.routers.fluid-calendar.rule" = "HostRegexp(`fluid-calendar.*`)";
              "traefik.http.routers.fluid-calendar.entrypoints" = "websecure";
              "traefik.http.routers.fluid-calendar.tls.certresolver" = "myresolver";
              "traefik.http.routers.fluid-calendar.tls.domains[0].main" = "fluid-calendar.emdecloud.de";
              "traefik.http.services.fluid-calendar.loadbalancer.server.port" = "3000";
            };
          };

          fluid-calendar-database = {
            image = "postgres:16-alpine";
            volumes = [ "/data/services/fluid-container/database:/var/lib/postgresql/data" ];
            networks = [ backendNetwork ];
            environment = {
              POSTGRES_DB = "fluid";
              POSTGRES_USER = "fluid";
              # POSTGRES_PASSWORD = "secure-password" # set via secret management;
            };
            environmentFiles = getServiceEnvFiles "fluid-calendar";
            labels = {
              # 🛡️ Traefik (disabled)
              "traefik.enable" = "false";
            };
          };
        };
    };
}
