{
  description = "NixOS module for the Homepage dashboard container";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    lib  = pkgs.lib;
  in {
    # Export a NixOS module
    nixosModule = { config, pkgs, ... }: {
      virtualisation.oci-containers = lib.mkMerge [
        config.virtualisation.oci-containers // {
          backend = "docker";
          containers.homepage = {
            image       = "ghcr.io/gethomepage/homepage:latest";
            ports       = [ "3000:3000" ];
            volumes     = [
              "/var/lib/homepage-config:/app/config"
              "/var/run/docker.sock:/var/run/docker.sock"
            ];
            environment = {
              HOMEPAGE_ALLOWED_HOSTS = "mahler";
            };
          };
        }
      ];
    };
  };
}
