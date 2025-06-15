{
  description = "Service flake exporting Homepage container config";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    config = pkgs.runCommand "config" { } ''
      mkdir -p $out/app/config
      cp -r ${./config}/* $out/app/config
    '';

    homepageBase = pkgs.dockerTools.pullImage {
      imageName = "ghcr.io/gethomepage/homepage";
      imageDigest = "sha256:4f923bf0e9391b3a8bc5527e539b022e92dcc8a3a13e6ab66122ea9ed030e196";
      sha256 = "sha256-ZvCdVqFQ8dKqunX94SCt8eXwBPcxAp3vpWvMJCsAxEw=";
    };

    # Build custom docker image with baked-in config
    homepageDerived = pkgs.dockerTools.buildImage {
      name = "homepage-derived";
      tag = "latest";
      fromImage = homepageBase;
      copyToRoot = config;
      config = {
        WorkingDir = "/app";
        Entrypoint = [ "docker-entrypoint.sh" ];
        Cmd = [ "node" "server.js" ];
      };
    };
  in {
    containers = {
      homepage = {
        image = "homepage-derived:latest";
        imageFile = homepageDerived;
        ports = [ "3000:3000" ];
        volumes = [
          "/etc/logs:/app/config/logs"
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
        environment = {
          HOMEPAGE_ALLOWED_HOSTS = "mahler";
        };
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.home.rule" = "Host(`mahler`)";
          "traefik.http.services.home.loadbalancer.server.port" = "3000";
        };
        autoStart = true;
      };
    };
  };
}
