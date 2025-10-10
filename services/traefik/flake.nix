{
  description = "Service flake exporting Traefik container config";

  outputs =
    { self, nixpkgs }:
    {
      name = "traefik";
      networks = {
        traefik = "";
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

          traefikRawImageReference = "traefik:v3.5.3@sha256:76ac93e6ff8c749c9b68e31698e93d3af38c6a6d10a6b989eeef97bf0b9887f8";
          traefikImageReference = parseDockerImageReference traefikRawImageReference;
          traefikImage = pkgs.dockerTools.pullImage {
            imageName = traefikImageReference.name;
            imageDigest = traefikImageReference.digest;
            finalImageTag = traefikImageReference.tag;
            sha256 = "sha256-/NqHpsUuGuLRmpP2wXyD9I3f3KyVWVs/pkRlMLFVSQQ=";
          };

          nginxRawImageReference = "nginx:1.29.2-alpine@sha256:7c1b9a91514d1eb5288d7cd6e91d9f451707911bfaea9307a3acbc811d4aa82e";
          nginxImageReference = parseDockerImageReference nginxRawImageReference;
          nginxImage = pkgs.dockerTools.pullImage {
            imageName = nginxImageReference.name;
            imageDigest = nginxImageReference.digest;
            finalImageTag = nginxImageReference.tag;
            sha256 = "sha256-QT2eDDKD8AkWMvJTarMJ/751cEfpiWbM1u1Gllc+QkE=";
          };
        in
        {
          traefik = {
            image = traefikImageReference.name + ":" + traefikImageReference.tag;
            imageFile = traefikImage;
            ports = [
              "80:80"
              "443:443"
              "8080:8080"
            ];
            extraOptions = [ "--dns=1.1.1.1" ];
            networks = [
              "traefik"
              "frp-ingress"
            ];
            environmentFiles = getServiceEnvFiles "traefik";
            volumes = [
              "/var/run/docker.sock:/var/run/docker.sock"
              "${./config/traefik.toml}:/traefik.toml:ro"
              "/data/services/traefik/certs:/certs"
            ];
            cmd = [
              "--configFile=traefik.toml"
            ];
            labels = {
              "homepage.group" = "Utilities";
              "homepage.name" = "Traefik";
              "homepage.icon" = "traefik";
              "homepage.href" = "http://${hostname}:8080";
              "homepage.description" = "Reverse proxy dashboard";
            };
          };

          error-pages = {
            image = nginxImageReference.name + ":" + nginxImageReference.tag;
            imageFile = nginxImage;
            networks = [
              "traefik"
            ];
            volumes = [
              "${./config/error.html}:/usr/share/nginx/html/error.html:ro"
              "${./config/nginx.conf}:/etc/nginx/nginx.conf:ro"
            ];
            labels = {
              "traefik.enable" = "true";

              # # Catch-all router (lowest priority)
              "traefik.http.routers.catchall.rule" = "PathPrefix(`/`)";
              "traefik.http.routers.catchall.priority" = "1";
              "traefik.http.routers.catchall.entrypoints" = "web";

              # Define the service used by the catchall router
              "traefik.http.services.catchall-service.loadbalancer.server.port" = "80";

              # Optional: Add a middleware to customize response (static page)
              "traefik.http.routers.catchall.middlewares" = "error-mw";
              "traefik.http.middlewares.error-mw.errors.status" = "404";
              "traefik.http.middlewares.error-mw.errors.service" = "catchall-service";
              "traefik.http.middlewares.error-mw.errors.query" = "/error.html";
            };
          };
        };
    };
}
