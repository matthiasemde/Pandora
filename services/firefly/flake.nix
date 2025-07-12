{
  description = "Firefly III service flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      name = "firefly";
      appName = "${name}-app";
      dbName = "${name}-db";
      backendNetwork = "firefly-backend";
    in
    {
      inherit name;
      dependencies = {
        networks = {
          ${backendNetwork} = "";
        };
      };
      containers =
        { hostname, getServiceEnvFiles, ... }:
        let
          host = "firefly.${hostname}.local";
        in
        {
          ${appName} = {
            image = "fireflyiii/core:version-6.2.19";
            volumes = [
              "/data/services/firefly/app/upload:/var/www/html/storage/upload"
            ];
            networks = [
              "traefik"
              "${backendNetwork}"
            ];
            environmentFiles = getServiceEnvFiles name ++ [ ./.env ];
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.${appName}.rule" = "HostRegexp(`firefly.*`)";
              "traefik.http.services.${appName}.loadbalancer.server.port" = "8080";

              # Homepage integration
              "homepage.group" = "Life Management";
              "homepage.name" = "Firefly";
              "homepage.icon" = "firefly";
              "homepage.href" = "http://${host}";
              "homepage.description" = "Finance managment";
            };
          };

          ${dbName} = {
            image = "mariadb:lts";
            volumes = [
              "/data/services/firefly/db:/var/lib/mysql"
            ];
            networks = [ "${backendNetwork}" ];
            environmentFiles = getServiceEnvFiles name ++ [ ./.db.env ];
            labels = {
              "traefik.enable" = "false";
            };
          };

          # firefly-cron = {
          #   image = "alpine";
          #   restartPolicy = "always";
          #   envFile = "/etc/firefly-iii/.env";
          #   command = ''
          #     sh -c "
          #       apk add tzdata && \
          #       ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
          #       echo '0 3 * * * wget -qO- http://${host(hostname)}/api/v1/cron/PLEASE_REPLACE_WITH_32_CHAR_CODE;echo' | crontab - && \
          #       crond -f -L /dev/stdout"
          #   '';
          # };
        };
    };
}
