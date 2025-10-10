{
  description = "Immich container flake";

  outputs =
    { self, nixpkgs }:
    let
      backendNetwork = "immich-backend";
    in
    {
      name = "immich";
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

          immichAppRawImageReference = "ghcr.io/immich-app/immich-server:v1.142.1@sha256:06bc7715fa4c4a1641bd0b566c949cd7327f420632b480389fd4d1e70665d046";
          immichAppImageReference = parseDockerImageReference immichAppRawImageReference;
          immichAppImage = pkgs.dockerTools.pullImage {
            imageName = immichAppImageReference.name;
            imageDigest = immichAppImageReference.digest;
            finalImageTag = immichAppImageReference.tag;
            sha256 = "sha256-ieXjtlmxIWojjuvHgLPpZ8cc/dDd6WkKPmB5u4AwXvg=";
          };

          immichMLRawImageReference = "ghcr.io/immich-app/immich-machine-learning:v1.142.1@sha256:9855f6a0a998db508ca97894997b17f3a0a61e9388b204d861110c19c42814eb";
          immichMLImageReference = parseDockerImageReference immichMLRawImageReference;
          immichMLImage = pkgs.dockerTools.pullImage {
            imageName = immichMLImageReference.name;
            imageDigest = immichMLImageReference.digest;
            finalImageTag = immichMLImageReference.tag;
            sha256 = "sha256-6INEsn30aYfaQY/FGQC5Cyue+3jGc7yMa8WF2U75IoM=";
          };

          immichRedisRawImageReference = "docker.io/valkey/valkey:8-bookworm@sha256:fec42f399876eb6faf9e008570597741c87ff7662a54185593e74b09ce83d177";
          immichRedisImageReference = parseDockerImageReference immichRedisRawImageReference;
          immichRedisImage = pkgs.dockerTools.pullImage {
            imageName = immichRedisImageReference.name;
            imageDigest = immichRedisImageReference.digest;
            finalImageTag = immichRedisImageReference.tag;
            sha256 = "sha256-pRgJXPCztxizPzsRTPvBbNAxLC4XXBtIMKtz3joyLPk=";
          };

          immichDatabaseRawImageReference = "ghcr.io/immich-app/postgres:16-vectorchord0.4.3-pgvectors0.2.0@sha256:1a078b237c1d9b420b0ee59147386b4aa60d3a07a8e6a402fc84a57e41b043a4";
          immichDatabaseImageReference = parseDockerImageReference immichDatabaseRawImageReference;
          immichDatabaseImage = pkgs.dockerTools.pullImage {
            imageName = immichDatabaseImageReference.name;
            imageDigest = immichDatabaseImageReference.digest;
            finalImageTag = immichDatabaseImageReference.tag;
            sha256 = "sha256-kEW12MDS2g1naTj4NZCUuEiuP39zEZXeuvTqIcJHZYs=";
          };
        in
        {
          immich-app = {
            image = immichAppImageReference.name + ":" + immichAppImageReference.tag;
            imageFile = immichAppImage;
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "/data/services/immich/upload:/usr/src/app/upload"
              "/data/nas/files/Bilder:/usr/src/app/external/familie:ro"
              "/data/nas/home/Matthias/Bilder:/usr/src/app/external/matthias:ro"
              "/data/nas/home/Theresa/Bilder:/usr/src/app/external/theresa:ro"
            ];
            networks = [
              backendNetwork
              "traefik"
            ];
            environment = {
              DB_HOSTNAME = "immich-database";
              REDIS_HOSTNAME = "immich-redis";
            };
            environmentFiles = getServiceEnvFiles "immich";
            labels = {
              # 🛡️ Traefik
              "traefik.enable" = "true";
              "traefik.http.routers.immich.rule" = "HostRegexp(`immich.*`)";
              "traefik.http.routers.immich.entrypoints" = "websecure";
              "traefik.http.routers.immich.tls.certresolver" = "myresolver";
              "traefik.http.routers.immich.tls.domains[0].main" = "immich.emdecloud.de";
              "traefik.http.services.immich.loadbalancer.server.port" = "2283";

              # 🏠 Homepage integration
              "homepage.group" = "Media";
              "homepage.name" = "Immich";
              "homepage.icon" = "immich";
              "homepage.href" = "https://immich.emdecloud.de";
              "homepage.description" = "Home to all our memories";
            };
          };

          immich-machine-learning = {
            image = immichMLImageReference.name + ":" + immichMLImageReference.tag;
            imageFile = immichMLImage;
            volumes = [ "immich-ml-cache:/cache" ];
            networks = [ backendNetwork ];
            labels = {
              # 🛡️ Traefik (disabled)
              "traefik.enable" = "false";
            };
          };

          immich-redis = {
            image = immichRedisImageReference.name + ":" + immichRedisImageReference.tag;
            imageFile = immichRedisImage;
            networks = [ backendNetwork ];
            labels = {
              # 🛡️ Traefik (disabled)
              "traefik.enable" = "false";
            };
          };

          immich-database = {
            image = immichDatabaseImageReference.name + ":" + immichDatabaseImageReference.tag;
            imageFile = immichDatabaseImage;
            networks = [ backendNetwork ];
            environment = {
              # POSTGRES_PASSWORD = set via secret management (use only the characters `A-Za-z0-9`);
              POSTGRES_USER = "postgres";
              POSTGRES_DB = "immich";
              POSTGRES_INITDB_ARGS = "--data-checksums";
            };
            volumes = [ "/data/services/immich/database:/var/lib/postgresql/data" ];
            environmentFiles = getServiceEnvFiles "immich";
            labels = {
              # 🛡️ Traefik (disabled)
              "traefik.enable" = "false";
            };
          };
        };
    };
}
