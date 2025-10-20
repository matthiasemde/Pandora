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
        {
          domain,
          mkTraefikLabels,
          getServiceEnvFiles,
          parseDockerImageReference,
          ...
        }:
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          paperlessRawImageReference = "ghcr.io/paperless-ngx/paperless-ngx:2.18.4@sha256:3421ebe06ed27662d014046cf5089e612de853aae0c676a2bc72f73b38080e57";
          paperlessImageReference = parseDockerImageReference paperlessRawImageReference;
          paperlessImage = pkgs.dockerTools.pullImage {
            imageName = paperlessImageReference.name;
            imageDigest = paperlessImageReference.digest;
            finalImageTag = paperlessImageReference.tag;
            sha256 = "sha256-d5YY0aTl/Tw6j1hFqV/Ef68VyzhuMWPEfxRbvd2lf1Q=";
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
          paperless-app = {
            image = paperlessImageReference.name + ":" + paperlessImageReference.tag;
            imageFile = paperlessImage;
            environment = {
              "PAPERLESS_URL" = "https://paperless.${domain}";
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

              # SSO Configuration
              "PAPERLESS_ENABLE_ALLAUTH" = "true";
              "PAPERLESS_APPS" = "allauth.socialaccount.providers.openid_connect";
              "PAPERLESS_SOCIALACCOUNT_PROVIDERS" = ''
                {
                  "openid_connect": {
                    "APPS": [
                      {
                        "provider_id": "authentik",
                        "name": "authentik",
                        "client_id": "MbfRgCUPQJ5HUybc2X8mB52cYFvyCVNt2hXgHOCV",
                        "settings": {
                          "server_url": "https://auth.emdecloud.de/application/o/paperless/.well-known/openid-configuration",
                          "claims": {"username": "email"}
                        }
                      }
                    ],
                    "OAUTH_PKCE_ENABLED": "True"
                  }
                }
              '';
              "PAPERLESS_AUTO_LOGIN" = "true";
              "PAPERLESS_AUTO_CREATE" = "true";
              "PAPERLESS_LOGOUT_REDIRECT_URL" = "https://auth.emdecloud.de/application/o/paperless/end-session/";
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
            labels =
              (mkTraefikLabels {
                name = "paperless";
                port = "8000";
              })
              // {
                # 🏠 Homepage integration
                "homepage.group" = "Life Management";
                "homepage.name" = "Paperless";
                "homepage.icon" = "paperless";
                "homepage.href" = "https://paperless.${domain}";
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
