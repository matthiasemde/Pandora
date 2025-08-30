{
  description = "Pterodactyl container flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs =
    { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      # -------------------------------------------------------------------
      # Panel Image
      # -------------------------------------------------------------------
      panelSrc = pkgs.fetchFromGitHub {
        owner = "pterodactyl";
        repo = "panel";
        rev = "v1.11.11";
        # replace this with the real sha256 (or run nix to get the expected one)
        sha256 = "sha256-Os8fTkruiUh6+ec5txhVgXPSDC2/LaCtvij7rQuWy0U=";
      };

      panelDerivation = pkgs.runCommand "panel-fs" { } ''
        mkdir -p $out/var/www/pterodactyl
        cp -r ${panelSrc}/* $out/var/www/pterodactyl/
        chmod -R 755 $out/var/www/pterodactyl || true
      '';

      # Create a small package that provides nginx site, php-fpm config and start script
      panelConfig = pkgs.runCommand "panel-config" { } ''
        mkdir -p $out/etc/nginx/sites-available $out/etc/nginx/sites-enabled \
                $out/etc $out/usr/local/bin

        cp ${./config/nginx.conf} $out/etc/nginx/sites-available/pterodactyl.conf
        ln -s /etc/nginx/sites-available/pterodactyl.conf $out/etc/nginx/sites-enabled/pterodactyl.conf || true

        cp ${./config/php.conf} $out/etc/php-fpm.conf

        # startup script that starts php-fpm and nginx
        cat > $out/usr/local/bin/start-panel <<'EOF'
        #!/bin/sh
        set -e

        # start php-fpm with our config in foreground
        echo "Starting php-fpm..."
        php-fpm --nodaemonize --fpm-config /etc/php-fpm.conf &

        # start nginx in foreground
        echo "Starting nginx..."
        nginx -g 'daemon off;'
        EOF

        chmod +x $out/usr/local/bin/start-panel
      '';

      phpEnv = pkgs.php.buildEnv {
        extensions =
          { enabled, all }:
          enabled
          ++ (with all; [
            openssl
            gd
            mysqli
            pdo_mysql
            mbstring
            tokenizer
            bcmath
            # xml
            curl
            zip
          ]);
        extraConfig = "memory_limit = 512M";
      };

      panelImage = pkgs.dockerTools.buildImage {
        name = "pterodactyl-panel";
        tag = "v1.0.0";
        copyToRoot = pkgs.buildEnv {
          name = "panel-root";
          paths = with pkgs; [
            bashInteractive # instead of plain bash → has readline enabled
            coreutils
            ncurses # provides terminfo for arrow keys
            nginx
            phpEnv # contains php + extensions
            phpEnv.packages.composer
            panelDerivation
            panelConfig
          ];
          pathsToLink = [
            "/bin"
            "/var/www/pterodactyl"
            "/etc"
            "/usr/local/bin"
          ];
        };

        config = {
          Cmd = [ "/usr/local/bin/start-panel" ];
          WorkingDir = "/var/www/pterodactyl";
          # ExposedPorts = { "80/tcp" = {}; };
        };
      };

      # -------------------------------------------------------------------
      # Wings Image
      # -------------------------------------------------------------------
      wingsBin = pkgs.fetchurl {
        url = "https://github.com/pterodactyl/wings/releases/download/v1.11.13/wings_linux_amd64";
        sha256 = "aca5fa45ddf1c10f092c16dd758b920d8a3fa9f91c37aacc62745e72958bf71a";
      };

      wingsDerivation = pkgs.runCommand "wings-fs" { } ''
        mkdir -p $out/usr/local/bin/wings
        cp ${wingsBin} $out/usr/local/bin/wings
        chmod u+x $out/usr/local/bin/wings
      '';

      wingsImage = pkgs.dockerTools.buildImage {
        name = "pterodactyl-wings";
        tag = "v1.0.0";

        copyToRoot = pkgs.buildEnv {
          name = "wings-root";
          paths = with pkgs; [
            bash
            coreutils
            wingsDerivation
          ];
        };

        config = {
          Entrypoint = [ "/usr/local/bin/wings" ];
        };
      };

      backendNetwork = "pterodactyl-backend";
    in
    {
      name = "pterodactyl";
      dependencies = {
        networks = {
          ${backendNetwork} = "";
        };
      };
      containers =
        { hostname, getServiceEnvFiles, ... }:
        {
          # ---------------------------
          # Panel
          # ---------------------------
          pterodactyl-panel = {
            image = "pterodactyl-panel:v1.0.0";
            imageFile = panelImage;
            volumes = [
              "/data/services/pterodactyl/panel:/app"
            ];
            networks = [
              backendNetwork
              "traefik"
            ];
            environment = {
              APP_ENV = "production";
              APP_URL = "https://pterodactyl.emdecloud.de";
              DB_HOST = "pterodactyl-database";
              DB_DATABASE = "pterodactyl";
              DB_USERNAME = "pterodactyl";
              # DB_PASSWORD via secrets
              CACHE_DRIVER = "redis";
              REDIS_HOST = "pterodactyl-redis";
            };
            environmentFiles = getServiceEnvFiles "pterodactyl";
            labels = {
              # 🛡️ Traefik
              "traefik.enable" = "true";
              "traefik.http.routers.pterodactyl.rule" = "HostRegexp(`pterodactyl.*`)";
              "traefik.http.routers.pterodactyl.entrypoints" = "websecure";
              "traefik.http.routers.pterodactyl.tls.certresolver" = "myresolver";
              "traefik.http.routers.pterodactyl.tls.domains[0].main" = "pterodactyl.emdecloud.de";
              "traefik.http.services.pterodactyl.loadbalancer.server.port" = "80";

              # 🏠 Homepage integration
              "homepage.group" = "Games";
              "homepage.name" = "Pterodactyl";
              "homepage.icon" = "gamepad-variant";
              "homepage.href" = "https://pterodactyl.emdecloud.de";
              "homepage.description" = "Game server management";
            };
          };

          # ---------------------------
          # Database
          # ---------------------------
          pterodactyl-database = {
            image = "mariadb:10.6";
            volumes = [
              "/data/services/pterodactyl/database:/var/lib/mysql"
            ];
            networks = [ backendNetwork ];
            environment = {
              MYSQL_DATABASE = "pterodactyl";
              MYSQL_USER = "pterodactyl";
              # MYSQL_ROOT_PASSWORD = "rootpassword"; # use secrets
              # MYSQL_PASSWORD via secrets
            };
            environmentFiles = getServiceEnvFiles "pterodactyl";
            labels = {
              # 🛡️ Traefik (disabled)
              "traefik.enable" = "false";
            };
          };

          # ---------------------------
          # Redis
          # ---------------------------
          pterodactyl-redis = {
            image = "redis:7";
            networks = [ backendNetwork ];
            volumes = [
              "/data/services/pterodactyl/redis:/data"
            ];
            labels = {
              # 🛡️ Traefik (disabled)
              "traefik.enable" = "false";
            };
          };

          # ---------------------------
          # Wings
          # ---------------------------
          pterodactyl-wings = {
            image = "pterodactyl-wings:v1.0.0";
            imageFile = wingsImage;
            # privileged = true;
            networks = [ backendNetwork ];
            volumes = [
              "/var/run/docker.sock:/var/run/docker.sock"
              # "/etc/pterodactyl:/etc/pterodactyl"
              "/data/services/pterodactyl/wings:/var/lib/pterodactyl"
            ];
            environmentFiles = getServiceEnvFiles "pterodactyl";
            labels = {
              # 🛡️ Traefik (disabled)
              "traefik.enable" = "false";
            };
          };
        };
    };
}
