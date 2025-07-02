{
  description = "Service flake exporting Traefik container config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs =
    { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      name = "traefik";
      networks = {
        traefik = "";
      };
      containers =
        { hostname, ... }:
        {
          traefik = {
            image = "traefik:v3.4.3";
            ports = [
              "80:80"
              "443:443"
              "8080:8080"
            ];
            networks = [ "traefik" ];
            volumes = [
              "/etc/traefik:/etc/traefik"
              "/var/run/docker.sock:/var/run/docker.sock"
            ];
            cmd = [
              "--api.insecure=true"
              "--providers.docker=true"
              "--entrypoints.web.address=:80"
              "--entrypoints.websecure.address=:443"
            ];
            labels = {
              "homepage.group" = "Utilities";
              "homepage.name" = "Traefik";
              "homepage.href" = "http://${hostname}:8080";
              "homepage.description" = "Reverse proxy dashboard";
            };
          };
        };
    };
}
