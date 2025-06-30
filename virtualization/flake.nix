{
  description = "Generic virtualization flake: a reusable NixOS module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs =
    { self, ... }:
    {
      nixosModules.default =
        {
          config,
          pkgs,
          lib,
          hostname,
          services,
          getServiceEnvFiles,
          ...
        }:
        let
          mergedContainers = lib.foldl' (
            acc: service: acc // service.containers { inherit hostname getServiceEnvFiles; }
          ) { } services;
          mergedNetworks = lib.foldl' (
            acc: service: acc // (if service ? networks then service.networks else { })
          ) { } services;
        in
        {
          # Declare all containers under oci-containers
          virtualisation.oci-containers = {
            backend = "docker";
            containers = mergedContainers;
          };

          # Create an activation script for each newtwork to be created at activation
          system.activationScripts = lib.listToAttrs (
            lib.mapAttrsToList (name: options: {
              name = "create_${name}_network";
              value = ''
                ${pkgs.docker}/bin/docker network inspect ${name} >/dev/null 2>&1 || \
                ${pkgs.docker}/bin/docker network create ${options} ${name}
              '';
            }) mergedNetworks
          );
        };
    };
}
