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
        { getServiceEnvFiles, parseDockerImageReference, ... }:
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          synapseRawImageReference = "matrixdotorg/synapse:v1.121.1@sha256:7fb8c0a74d8e3bbc37c2e29629f0fbcc7354f42c6ddfe1ea7e59271fb9e68dfe";
          synapseImageReference = parseDockerImageReference synapseRawImageReference;
          synapseImage = pkgs.dockerTools.pullImage {
            imageName = synapseImageReference.name;
            imageDigest = synapseImageReference.digest;
            finalImageTag = synapseImageReference.tag;
            sha256 = "sha256-KYJUvpNnSUVB2RCbH/Sw/VZMcG8y3MFUKgJF+L3MYU0=";
          };

          postgresRawImageReference = "docker.io/library/postgres:18-alpine@sha256:f898ac406e1a9e05115cc2efcb3c3abb3a92a4c0263f3b6f6aaae354cbb1953a";
          postgresImageReference = parseDockerImageReference postgresRawImageReference;
          postgresImage = pkgs.dockerTools.pullImage {
            imageName = postgresImageReference.name;
            imageDigest = postgresImageReference.digest;
            finalImageTag = postgresImageReference.tag;
            sha256 = "sha256-CuB9K0hS5dbVvjwA+2p0HAaz9tKmnd7Ls4Ach00k/Gk=";
          };

          redisRawImageReference = "docker.io/library/redis:8@sha256:b83648c7ab6752e1f52b88ddf5dabc11987132336210d26758f533fb01325865";
          redisImageReference = parseDockerImageReference redisRawImageReference;
          redisImage = pkgs.dockerTools.pullImage {
            imageName = redisImageReference.name;
            imageDigest = redisImageReference.digest;
            finalImageTag = redisImageReference.tag;
            sha256 = "sha256-CXa5elUnGSjjqWhPDs+vlIuLr/7XLcM19zkQPijjUrY=";
          };
        in
        {
          synapse-db = {
            image = postgresImageReference.name + ":" + postgresImageReference.tag;
            imageFile = postgresImage;
            environment = {
              "POSTGRES_USER" = "synapse";
              # "POSTGRES_PASSWORD" = "password"; # set via secret-mgmt
              "POSTGRES_DB" = "synapse";
              "POSTGRES_INITDB_ARGS" = "--encoding=UTF8 --lc-collate=C --lc-ctype=C";
            };
            environmentFiles = getServiceEnvFiles "synapse";
            volumes = [
              "/data/services/synapse/db:/var/lib/postgresql/data"
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
              "/data/services/synapse/data:/data"
              "${./config/homeserver.yaml}:/data/homeserver.yaml:ro"
              "${./config/log.config}:/data/log.config:ro"
            ];
            networks = [
              "traefik"
              backendNetwork
            ];
            labels = {
              # 🛡️ Traefik - Client API
              "traefik.enable" = "true";
              
              # Client API router (port 8008)
              "traefik.http.routers.synapse-client.rule" = "HostRegexp(`matrix.*`)";
              "traefik.http.routers.synapse-client.entrypoints" = "websecure";
              "traefik.http.routers.synapse-client.tls.certresolver" = "myresolver";
              "traefik.http.routers.synapse-client.tls.domains[0].main" = "matrix.mahler.local";
              "traefik.http.routers.synapse-client.service" = "synapse-client-service";
              "traefik.http.services.synapse-client-service.loadbalancer.server.port" = "8008";

              # Federation API router (port 8448)
              "traefik.http.routers.synapse-federation.rule" = "HostRegexp(`synapse.*`)";
              "traefik.http.routers.synapse-federation.entrypoints" = "websecure";
              "traefik.http.routers.synapse-federation.tls.certresolver" = "myresolver";
              "traefik.http.routers.synapse-federation.tls.domains[0].main" = "synapse.mahler.local";
              "traefik.http.routers.synapse-federation.service" = "synapse-federation-service";
              "traefik.http.services.synapse-federation-service.loadbalancer.server.port" = "8448";

              # 🏠 Homepage integration
              "homepage.group" = "Communication";
              "homepage.name" = "Matrix Synapse";
              "homepage.icon" = "matrix";
              "homepage.href" = "https://matrix.mahler.local";
              "homepage.description" = "Matrix homeserver";
            };
          };
        };
    };
}
