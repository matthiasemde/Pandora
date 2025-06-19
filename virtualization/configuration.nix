# A NixOS module: merges any number of service flakes into Docker containers
{ config, pkgs, lib, hostname, services ? [], ... }:

let
  mergedContainers = lib.foldl' (acc: service: acc // service.containers { inherit hostname; }) {} services;
in {
  # Declare all containers under oci-containers
  virtualisation.oci-containers = {
    backend    = "docker";
    containers = mergedContainers;
  };
}
