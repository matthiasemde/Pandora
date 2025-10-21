{
  description = "Matrix Synapse service";

  outputs =
    { self, nixpkgs }:
    let
      backendNetwork = "synapse-backend";
    in
    {
      name = "synapse";
      dependencies = {
        networks = {
          ${backendNetwork} = "";
        };
      };
      containers =
        {
          domain,
          mkTraefikLabels,
          getServiceEnvFiles,
          parseDockerImageReference,
          ...
        }:
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          synapseRawImageReference = "matrixdotorg/synapse:v1.140.0@sha256:0a2a45ceef86de314fc62c2c2ba78b7468d530be5c5ffa7a91cbe4f725a74c1b";
          synapseImageReference = parseDockerImageReference synapseRawImageReference;
          synapseImage = pkgs.dockerTools.pullImage {
            imageName = synapseImageReference.name;
            imageDigest = synapseImageReference.digest;
            finalImageTag = synapseImageReference.tag;
            sha256 = "sha256-KPusLlnNY3pKHs2yXL9W/Txb/bHp+wodtcA+CMxnROM=";
          };

          postgresRawImageReference = "postgres:18@sha256:073e7c8b84e2197f94c8083634640ab37105effe1bc853ca4d5fbece3219b0e8";
          postgresImageReference = parseDockerImageReference postgresRawImageReference;
          postgresImage = pkgs.dockerTools.pullImage {
            imageName = postgresImageReference.name;
            imageDigest = postgresImageReference.digest;
            finalImageTag = postgresImageReference.tag;
            sha256 = "sha256-zH0xxBUum8w4fpGFV6r76jI7ayJuXC8G0qY1Dm26opU=";
          };

          redisRawImageReference = "redis:8@sha256:f0957bcaa75fd58a9a1847c1f07caf370579196259d69ac07f2e27b5b389b021";
          redisImageReference = parseDockerImageReference redisRawImageReference;
          redisImage = pkgs.dockerTools.pullImage {
            imageName = redisImageReference.name;
            imageDigest = redisImageReference.digest;
            finalImageTag = redisImageReference.tag;
            sha256 = "sha256-CXa5elUnGSjjqWhPDs+vlIuLr/7XLcM19zkQPijjUrY=";
          };
        in
        {
          synapse-database = {
            image = postgresImageReference.name + ":" + postgresImageReference.tag;
            imageFile = postgresImage;
            environment = {
              "POSTGRES_USER" = "synapse";
              # "POSTGRES_PASSWORD" = "password"; # set via secret-mgmt
              "POSTGRES_DB" = "synapse";
              "POSTGRES_INITDB_ARGS" = "--encoding=UTF8 --locale=C";
            };
            environmentFiles = getServiceEnvFiles "synapse";
            volumes = [
              "/data/services/synapse/database:/var/lib/postgresql/18/docker"
            ];
            networks = [ backendNetwork ];
            labels = {
              "traefik.enable" = "false";
            };
          };

          synapse-redis = {
            image = redisImageReference.name + ":" + redisImageReference.tag;
            imageFile = redisImage;
            cmd = [
              "--save"
              "60"
              "1"
              "--loglevel"
              "warning"
            ];
            volumes = [
              "/data/services/synapse/redis:/data"
            ];
            networks = [ backendNetwork ];
            labels = {
              "traefik.enable" = "false";
            };
          };

          synapse-app = {
            image = synapseImageReference.name + ":" + synapseImageReference.tag;
            imageFile = synapseImage;
            environment = {
              "SYNAPSE_CONFIG_PATH" = "/data/homeserver.yaml";
            };
            environmentFiles = getServiceEnvFiles "synapse";
            volumes = [
              "/data/services/synapse/app:/data"
              "${./config/homeserver.yaml.j2}:/data/homeserver.yaml.j2:ro"
              "${./render-config.py}:/render-config.py:ro"
              "${./entrypoint.sh}:/entrypoint.sh:ro"
              "${./config/log.config}:/data/log.config:ro"
            ];
            entrypoint = "/entrypoint.sh";
            networks = [
              "traefik"
              backendNetwork
            ];
            labels =
              (mkTraefikLabels {
                name = "matrix";
                port = "8008";
              })
              // {
                # --- Public federatior router ---
                "traefik.http.routers.matrix-federation.entrypoints" = "federation";
                "traefik.http.routers.matrix-federation.rule" = "Host(`matrix.${domain}`)";
                "traefik.http.routers.matrix-federation.tls.certresolver" = "myresolver";
                "traefik.http.routers.matrix-federation.tls.domains[0].main" = "matrix.${domain}";
                "traefik.http.routers.matrix-federation.service" = "matrix";

                # 🏠 Homepage integration
                "homepage.group" = "Communication";
                "homepage.name" = "Matrix Synapse";
                "homepage.icon" = "matrix";
                "homepage.href" = "https://matrix.${domain}";
                "homepage.description" = "Matrix homeserver";
              };
          };
        };
    };
}
