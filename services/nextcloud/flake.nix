{
  description = "Nextcloud container flake";

  outputs =
    { self, nixpkgs }:
    let
      backendNetwork = "nextcloud-backend";
    in
    {
      name = "nextcloud";
      dependencies = {
        networks = {
          ${backendNetwork} = "";
        };
      };
      containers =
        {
          hostname,
          getServiceEnvFiles,
          parseDockerImageReference,
          ...
        }:
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          postgresRawImageReference = "postgres:18@sha256:073e7c8b84e2197f94c8083634640ab37105effe1bc853ca4d5fbece3219b0e8";
          postgresImageReference = parseDockerImageReference postgresRawImageReference;
          postgresImage = pkgs.dockerTools.pullImage {
            imageName = postgresImageReference.name;
            imageDigest = postgresImageReference.digest;
            finalImageTag = postgresImageReference.tag;
            sha256 = "sha256-oG5Do29b4CSok3H6mSk/xYiHeyJd4XJShwdkgO3A6D0=";
          };

          redisRawImageReference = "redis:7@sha256:88e81357a782cf72ad2c4a8bac4391d193bae19ab119bb1bff3ea9344ab675be";
          redisImageReference = parseDockerImageReference redisRawImageReference;
          redisImage = pkgs.dockerTools.pullImage {
            imageName = redisImageReference.name;
            imageDigest = redisImageReference.digest;
            finalImageTag = redisImageReference.tag;
            sha256 = "sha256-VigxNiQYrKw8IeKNGTEi01chwwccka286qdmelz6Idc=";
          };
        in
        {
          nextcloud-app = {
            image = "nextcloud-derived:v1.1.1";
            volumes = [
              "/data/services/nextcloud/app:/var/www/html"
            ];
            networks = [
              backendNetwork
              "traefik"
            ];
            environment = {
              POSTGRES_HOST = "nextcloud-database";
              POSTGRES_DB = "nextcloud";
              POSTGRES_USER = "nextcloud";
              # POSTGRES_PASSWORD = "secure-password" # set via secret management;
              REDIS_HOST = "nextcloud-redis";
              NEXTCLOUD_ADMIN_USER = "admin";
              # NEXTCLOUD_ADMIN_PASSWORD = "adminpassword" # set via secret management;
              NEXTCLOUD_TRUSTED_DOMAINS = "nextcloud.emdecloud.de nextcloud.mahler.local";
              # Necessary to allow clients to connect through the reverse proxy
              OVERWRITEPROTOCOL = "https";
              OVERWRITECLIURL = "https://nextcloud.emdecloud.de";
            };
            environmentFiles = getServiceEnvFiles "nextcloud";
            labels = {
              # 🛡️ Traefik
              "traefik.enable" = "true";
              "traefik.http.routers.nextcloud.rule" = "HostRegexp(`nextcloud.*`)";
              "traefik.http.routers.nextcloud.entrypoints" = "websecure";
              "traefik.http.routers.nextcloud.tls.certresolver" = "myresolver";
              "traefik.http.routers.nextcloud.tls.domains[0].main" = "nextcloud.emdecloud.de";
              "traefik.http.services.nextcloud.loadbalancer.server.port" = "80";

              # 🏠 Homepage integration
              "homepage.group" = "Media";
              "homepage.name" = "Nextcloud";
              "homepage.icon" = "nextcloud";
              "homepage.href" = "https://nextcloud.emdecloud.de";
              "homepage.description" = "Home to all our data";
            };
          };

          nextcloud-database = {
            image = postgresImageReference.name + ":" + postgresImageReference.tag;
            imageFile = postgresImage;
            volumes = [ "/data/services/nextcloud/database:/var/lib/postgresql/data" ];
            networks = [ backendNetwork ];
            environment = {
              POSTGRES_DB = "nextcloud";
              POSTGRES_USER = "nextcloud";
              # POSTGRES_PASSWORD = "secure-password" # set via secret management;
            };
            environmentFiles = getServiceEnvFiles "nextcloud";
            labels = {
              # 🛡️ Traefik (disabled)
              "traefik.enable" = "false";
            };
          };

          nextcloud-redis = {
            image = redisImageReference.name + ":" + redisImageReference.tag;
            imageFile = redisImage;
            networks = [ backendNetwork ];
            labels = {
              # 🛡️ Traefik (disabled)
              "traefik.enable" = "false";
            };
          };
        };
    };
}
