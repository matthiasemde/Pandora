{
  description = "AdGuard Home container module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;

    config = pkgs.runCommand "config" { } ''
      mkdir -p $out/opt/adguardhome/conf
      cp -r ${./config}/* $out/opt/adguardhome/conf
    '';

    adguardBase = pkgs.dockerTools.pullImage {
      imageName = "adguard/adguardhome";
      imageDigest = "sha256:ccacb25ed2f53c06d89b2b3849335af74d89587fbcba083a52198824269ddd9b";
      sha256 = "sha256-hP6yYr0AHv1wDZ7BHzhx4GZGKL9wPy8wEaKjrDvh4KE=";
    };

    # Build custom docker image with baked-in config
    adguardDerived = pkgs.dockerTools.buildImage {
      name = "adguard-derived";
      tag = "latest";
      fromImage = adguardBase;
      copyToRoot = config;
      config = {
        Entrypoint = ["/opt/adguardhome/AdGuardHome"];
        Cmd = ["--no-check-update" "-c" "/opt/adguardhome/conf/AdGuardHome.yaml" "-w" "/opt/adguardhome/work"];
      };
    };
  in {
    containers = { hostname, ... }: {
      adguard = {
        image = "adguard-derived:latest";
        imageFile = adguardDerived;
        extraOptions = [
          "--network=macvlan0"
          "--ip=192.168.178.240"
        ];
        environment = { };
        volumes = [
          "/data/services/adguard/work:/opt/adguardhome/work"
        ];
        labels = {
          # Homepage integration
          "homepage.group" = "Network";
          "homepage.name" = "AdGuard";
          "homepage.icon" = "adguard-home";
          "homepage.href" = "http://adguard.${hostname}.local";
          "homepage.description" = "DNS-level ad blocking";
        };
      };
    };
  };
}
