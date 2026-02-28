{
  description = "Service flake exporting Web Projects static server container config";

  outputs =
    { self, nixpkgs }:
    {
      name = "web-projects";
      containers =
        {
          parseDockerImageReference,
          domain,
          mkTraefikLabels,
          ...
        }:
        {
          web-projects = {
            rawImageReference = "nginx:1.29.5-alpine@sha256:1d13701a5f9f3fb01aaa88cef2344d65b6b5bf6b7d9fa4cf0dca557a8d7702ba";
            nixSha256 = "sha256-qgeS1JFHApzVUad0UvVF1pPuvdvg0o2+Q3g8GXu1By8=";
            networks = [
              "traefik"
            ];
            volumes = [
              "/data/nas/home/Matthias/Documents/code/web-projects:/usr/share/nginx/html/projects:ro"
              "${./config/nginx.conf}:/etc/nginx/nginx.conf:ro"
              "${./config/index.html}:/usr/share/nginx/html/index.html:ro"
            ];
            labels = mkTraefikLabels {
              name = "web-projects";
              port = "80";
              useForwardAuth = false;
            } // {
              "homepage.group" = "Fun & Games";
              "homepage.name" = "Web Projects";
              "homepage.icon" = "nginx";
              "homepage.href" = "http://web-projects.${domain}";
              "homepage.description" = "Static web project showcase";
            };
          };
        };
    };
}
