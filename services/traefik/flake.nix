{
  description = "NixOS module for the Traefik reverse proxy container";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    lib  = pkgs.lib;
  in {
    nixosModule = { config, pkgs, ... }: {
      virtualisation.oci-containers = lib.mkMerge [
        config.virtualisation.oci-containers // {
          backend = "docker";
          containers.traefik = {
            image   = "traefik:latest";
            ports   = [ "80:80" "443:443" "8080:8080" ];
            volumes = [ "/etc/traefik:/etc/traefik" ];
            cmd     = [
              "--api.insecure=true"
              "--providers.docker=true"
              "--entrypoints.web.address=:80"
              "--entrypoints.websecure.address=:443"
            ];
          };
        }
      ];
    };
  };
}
