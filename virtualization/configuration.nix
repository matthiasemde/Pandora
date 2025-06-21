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

  # Declare a custom docker network fhich can be used by services like adguard
  systemd.services.macvlan-network = {
    description = "Create macvlan Docker network for LAN bridging";
    wantedBy = [ "docker.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "create-macvlan" ''
        ${pkgs.docker}/bin/docker network inspect macvlan0 >/dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create -d macvlan \
            --subnet=192.168.178.0/24 \
            --gateway=192.168.178.1 \
            --ip-range=192.168.178.240/28 \
            --ipv6 \
            --subnet=fdfb:7759:b7ce::/64 \
            --gateway=fdfb:7759:b7ce::2e91:abff:fea2:270e \
            -o parent=enp106s0f3u2 \
            macvlan0
      '';
      RemainAfterExit = true;
    };
  };
}
