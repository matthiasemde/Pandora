{
  description = "AdGuard Home container module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    lib = pkgs.lib;
  in {
    containers = { hostname, ... }: {
      adguard = {
        image = "adguard/adguardhome:latest";
        ports = [
          "53:53/udp"     # DNS
          "53:53/tcp"     # DNS over TCP
          "3001:3000"     # Web UI via Traefik
        ];
        environment = { };
        labels = {
          # Traefik reverse proxy
          "traefik.enable" = "true";
          "traefik.http.routers.adguard.rule" = "Host(`adguard.${hostname}`)";
          "traefik.http.routers.adguard.entrypoints" = "web";
          "traefik.http.services.adguard.loadbalancer.server.port" = "3000";

          # Homepage integration
          "homepage.group" = "Network";
          "homepage.name" = "AdGuard";
          "homepage.icon" = "adguard-home";
          "homepage.href" = "http://adguard.${hostname}";
          "homepage.description" = "DNS-level ad blocking";
        };
      };
    };
  };
}
