{
  description = "Vaultwarden container flake";

  outputs =
    { self, nixpkgs }:
    {
      name = "vaultwarden";
      containers =
        { getServiceEnvFiles, parseDockerImageReference, ... }:
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          vaultwardenRawImageReference = "vaultwarden/server:1.34.2@sha256:2981e809c332e46d49bd29e6a898ca5ba13fa431befabe52d0ce11ed237cb5ef";
          vaultwardenImageReference = parseDockerImageReference vaultwardenRawImageReference;
          vaultwardenImage = pkgs.dockerTools.pullImage {
            imageName = vaultwardenImageReference.name;
            imageDigest = vaultwardenImageReference.digest;
            finalImageTag = vaultwardenImageReference.tag;
            sha256 = "sha256-85c/SV7bz4mCcu8HOLyJchoscu1bkAIRYMF64lPzTDM=";
          };
        in
        {
          vaultwarden = {
            image = vaultwardenImageReference.name + ":" + vaultwardenImageReference.tag;
            imageFile = vaultwardenImage;
            extraOptions = [ "--dns=1.1.1.1" ];
            environment = {
              # Server hostname
              "DOMAIN" = "https://vaultwarden.emdecloud.de";
              "SIGNUPS_ALLOWED" = "false";
              # "ADMIN_TOKEN" = "xxxxxxxxxxxx" # set via secret management;
              "ORG_CREATION_USERS" = "matthias@emdemail.de";

              ## Mail settings
              "SMTP_HOST" = "mail.privateemail.com";
              "SMTP_FROM" = "no-reply@emdecloud.de";
              "SMTP_FROM_NAME" = "Vaultwarden";
              # "SMTP_USERNAME" = "username"; # set via secret management;
              # "SMTP_PASSWORD" = "password"; # set via secret management;
              "SMTP_TIMEOUT" = "15";
              "SMTP_SECURITY" = "force_tls";
              "SMTP_PORT" = "465";
            };
            environmentFiles = getServiceEnvFiles "vaultwarden";
            volumes = [
              "/data/services/vaultwarden/app:/data"
            ];
            networks = [ "traefik" ];
            labels = {
              # 🛡️ Traefik
              "traefik.enable" = "true";
              "traefik.http.routers.vaultwarden.rule" = "HostRegexp(`vaultwarden.*`)";
              "traefik.http.routers.vaultwarden.entrypoints" = "websecure";
              "traefik.http.routers.vaultwarden.tls.certresolver" = "myresolver";
              "traefik.http.routers.vaultwarden.tls.domains[0].main" = "vaultwarden.emdecloud.de";
              "traefik.http.services.vaultwarden.loadbalancer.server.port" = "80";

              # 🏠 Homepage integration
              "homepage.group" = "Life Management";
              "homepage.name" = "Vaultwarden";
              "homepage.icon" = "vaultwarden";
              "homepage.href" = "https://vaultwarden.emdecloud.de";
              "homepage.description" = "Password vault";
            };
          };
        };
    };
}
