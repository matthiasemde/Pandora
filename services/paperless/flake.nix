{
  description = "Paperless-NGX container flake";

  outputs =
    { self, nixpkgs }:
    let
      backendNetwork = "paperless-backend";
    in
    {
      name = "paperless";
      dependencies = {
        networks = {
          ${backendNetwork} = "";
        };
      };
      containers =
        { getServiceEnvFiles, parseDockerImageReference, ... }:
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          paperlessRawImageReference = "ghcr.io/paperless-ngx/paperless-ngx:2.18.4@sha256:3421ebe06ed27662d014046cf5089e612de853aae0c676a2bc72f73b38080e57";
          paperlessImageReference = parseDockerImageReference paperlessRawImageReference;
          paperlessImage = pkgs.dockerTools.pullImage {
            imageName = paperlessImageReference.name;
            imageDigest = paperlessImageReference.digest;
            finalImageTag = paperlessImageReference.tag;
            sha256 = "sha256-g6usmGwpbghIjEkdh/QfSsXw7w17E1v41f/qATv4Bvk=";
          };

          redisRawImageReference = "docker.io/library/redis:8@sha256:f0957bcaa75fd58a9a1847c1f07caf370579196259d69ac07f2e27b5b389b021";
          redisImageReference = parseDockerImageReference redisRawImageReference;
          redisImage = pkgs.dockerTools.pullImage {
            imageName = redisImageReference.name;
            imageDigest = redisImageReference.digest;
            finalImageTag = redisImageReference.tag;
            sha256 = "sha256-CXa5elUnGSjjqWhPDs+vlIuLr/7XLcM19zkQPijjUrY=";
          };
        in
        {
          paperless-app = {
            image = paperlessImageReference.name + ":" + paperlessImageReference.tag;
            imageFile = paperlessImage;
            extraOptions = [ "--dns=1.1.1.1" ];
            environment = {
              "PAPERLESS_URL" = "https://paperless.emdecloud.de";
              "PAPERLESS_ACCOUNT_ALLOW_SIGNUPS" = "false";
              "PAPERLESS_REDIS" = "redis://paperless-redis:6379";

              # SMTP
              "PAPERLESS_EMAIL_HOST" = "mail.privateemail.com";
              "PAPERLESS_EMAIL_PORT" = "465";
              "PAPERLESS_EMAIL_HOST_USER" = "no-reply@emdecloud.de";
              # "PAPERLESS_EMAIL_HOST_PASSWORD" = "password"; # set via secret management;
              "PAPERLESS_EMAIL_USE_SSL" = "true";

              # Configuration
              "PAPERLESS_CONSUMER_RECURSIVE" = "true";
              "PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS" = "true";
            };
            environmentFiles = getServiceEnvFiles "paperless";
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "/data/services/paperless/app/data:/usr/src/paperless/data"
              "/data/services/paperless/app/media:/usr/src/paperless/media"
              "/data/services/paperless/app/export:/usr/src/paperless/export"
              "/tmp/paperless-consumer:/usr/src/paperless/consume"
            ];
            networks = [
              "traefik"
              backendNetwork
            ];
            labels = {
              # 🛡️ Traefik
              "traefik.enable" = "true";
              "traefik.http.routers.paperless.rule" = "HostRegexp(`paperless.*`)";
              "traefik.http.routers.paperless.entrypoints" = "websecure";
              "traefik.http.routers.paperless.tls.certresolver" = "myresolver";
              "traefik.http.routers.paperless.tls.domains[0].main" = "paperless.emdecloud.de";
              "traefik.http.services.paperless.loadbalancer.server.port" = "8000";

              # 🏠 Homepage integration
              "homepage.group" = "Life Management";
              "homepage.name" = "Paperless";
              "homepage.icon" = "paperless";
              "homepage.href" = "https://paperless.emdecloud.de";
              "homepage.description" = "Digitize documents";
            };
          };

          paperless-redis = {
            image = redisImageReference.name + ":" + redisImageReference.tag;
            imageFile = redisImage;
            volumes = [
              "/data/services/paperless/redis:/data"
            ];
            networks = [ backendNetwork ];
            labels = {
              # 🛡️ Traefik (disabled)
              "traefik.enable" = "false";
            };
          };
        };
    };
}
