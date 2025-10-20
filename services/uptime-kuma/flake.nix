{
  description = "Uptime Kuma service flake";

  outputs =
    { self, nixpkgs }:
    {
      name = "uptime-kuma";
      dependencies = {
        networks = {
          "monitoring" = "";
        };
      };
      containers =
        {
          hostname,
          domain,
          parseDockerImageReference,
          mkTraefikLabels,
          ...
        }:
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          uptimeKumaRawImageReference = "louislam/uptime-kuma:1.23.17@sha256:0e192c54160b6e3a799dd1ebf4178430fc630a41cd1b6889a148e0e472494a55";
          uptimeKumaImageReference = parseDockerImageReference uptimeKumaRawImageReference;
          uptimeKumaImage = pkgs.dockerTools.pullImage {
            imageName = uptimeKumaImageReference.name;
            imageDigest = uptimeKumaImageReference.digest;
            finalImageTag = uptimeKumaImageReference.tag;
            sha256 = "sha256-oYw3Vdu7lc1KNN3oXAS8WR9Lj64gGogZVmO61naQTV0=";
          };
        in
        {
          uptime-kuma = {
            image = uptimeKumaImageReference.name + ":" + uptimeKumaImageReference.tag;
            imageFile = uptimeKumaImage;
            networks = [
              "traefik"
            ];
            volumes = [
              "/data/services/uptime-kuma:/app/data"
            ];
            environment = {
              UPTIME_KUMA_PORT = "3001";
            };
            labels =
              (mkTraefikLabels {
                name = "status";
                port = "3001";
              })
              // {
                "homepage.group" = "Monitoring";
                "homepage.name" = "Uptime Kuma";
                "homepage.icon" = "uptime-kuma";
                "homepage.href" = "https://status.${domain}";
                "homepage.description" = "Uptime monitoring and status page";
              };
          };
        };
    };
}
