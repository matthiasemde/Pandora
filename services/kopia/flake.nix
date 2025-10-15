{
  description = "Kopia Server container for de-duplicated backups";

  outputs =
    { self, nixpkgs }:
    {
      name = "kopia";
      containers =
        {
          hostname,
          mkTraefikLabels,
          getServiceEnvFiles,
          parseDockerImageReference,
          ...
        }:
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          kopiaRawImageReference = "kopia/kopia:20251015.0.22854@sha256:322189265e63a21bca4d908c5a4056df0c1872a29b2195bdbc33a987e596d816";
          kopiaImageReference = parseDockerImageReference kopiaRawImageReference;
          kopiaImage = pkgs.dockerTools.pullImage {
            imageName = kopiaImageReference.name;
            imageDigest = kopiaImageReference.digest;
            finalImageTag = kopiaImageReference.tag;
            sha256 = "sha256-+onyN8iEw9HbZ+ZQ4hYGQyI1kELR96wd8SGMrIOrT1s=";
          };
        in
        {
          kopia = {
            image = kopiaImageReference.name + ":" + kopiaImageReference.tag;
            imageFile = kopiaImage;
            networks = [
              "traefik"
            ];
            ports = [ "51515:51515" ];
            extraOptions = [ "--dns=1.1.1.1" ];
            ##########################
            ### The SYS_ADMIN capabilities are only required for
            ### mounting backups into the local file system.
            # capabilities = {
            #   SYS_ADMIN = true;
            # };
            # devices = [ "/dev/fuse:/dev/fuse" ];
            ##########################
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              # Mount local folders needed by kopia
              "/data/services/kopia/config/dir:/app/config"
              "/data/services/kopia/certs:/certs"
              # "/data/services/kopia/cache/dir:/app/cache"

              # "/data/services/kopia/logs/dir:/app/logs"
              # Mount local folders to snapshot
              "/data/services:/data/services:ro"
              "/data/nas:/data/nas:ro"
              # Mount repository location
              "/backup/kopia/repositories/main:/repository"
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
              # "--tls-generate-cert" # needed only once on first startup
              "--tls-cert-file"
              "/certs/kopia-mahler.cert"
              "--tls-key-file"
              "/certs/kopia-mahler.key"
              "--address"
              "0.0.0.0:51515"
            ];

            labels =
              (mkTraefikLabels {
                name = "kopia";
                port = "51515";
                passthrough = true;
              })
              // {
                "homepage.group" = "Utilities";
                "homepage.name" = "Kopia Server";
                "homepage.icon" = "kopia";
                "homepage.href" = "https://kopia.${hostname}.local";
                "homepage.description" = "Deduplicating backup service";
              };
          };
        };
    };
}
