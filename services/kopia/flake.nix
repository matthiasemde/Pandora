{
  description = "Kopia Server container for de-duplicated backups";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs =
    { self, nixpkgs, ... }:
    {
      name = "kopia";
      containers =
        { hostname, getServiceEnvFiles, ... }:
        {
          kopia = {
            image = "kopia/kopia:0.21.1";
            networks = [
              "traefik"
            ];
            ports = [ "51515:51515" ];
            extraOptions = [ "--dns=1.1.1.1" ];
            # mount the repo path (on your HDD)
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              # Mount local folders needed by kopia
              "/data/services/kopia/config/dir:/app/config"
              # "/data/services/kopia/cache/dir:/app/cache"

              # "/data/services/kopia/logs/dir:/app/logs"
              # Mount local folders to snapshot
              "/data/services:/data:ro"
              # Mount repository location
              "/data/backup/kopia/repositories/main:/repository"
              # Mount path for browsing mounted snapshots
              "/tmp/kopia-browse:/tmp:shared"
            ];
            environment = {
              "USER" = "User";
            };
            environmentFiles = getServiceEnvFiles "kopia";

            # startup: run the server, binding to all interfaces
            cmd = [
              "server"
              "start"
              # "--config-file"
              # "/app/server.config.json"
              "--disable-csrf-token-checks"
              "--insecure"
              "--address"
              "0.0.0.0:51515"
            ];

            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.kopia.rule" = "HostRegexp(`kopia.*`)";
              "traefik.http.routers.kopia.entrypoints" = "web";
              "traefik.http.services.kopia.loadbalancer.server.port" = "51515";

              "homepage.group" = "Utilities";
              "homepage.name" = "Kopia Server";
              "homepage.icon" = "kopia";
              "homepage.href" = "https://kopia.mahler.local";
            };
          };
        };
    };
}
