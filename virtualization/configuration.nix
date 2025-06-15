{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf;
in {
  # Docker rootless
  virtualisation.docker = {
    # disable system-wide Docker
    enable = false;

    rootless = {
      enable = true;
      setSocketVariable = true;
      # Optional: customize the rootless daemon (DNS, mirrors, etc.)
      daemon.settings = {
        "dns" = [ "1.1.1.1" "8.8.8.8" ];
        "registry-mirrors" = [ "https://mirror.gcr.io" ];
      };
    };
  };

  # Allow unprivileged users to bind services beginning form port 80
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;

  # Import service modules
  imports = [
    # Path relative to this file
    ../services/homepage
    ../services/traefik
  ];
}
