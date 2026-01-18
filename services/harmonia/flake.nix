{
  description = "Harmonia - Nix binary cache service";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Build harmonia from nixpkgs
      harmoniaPkg = pkgs.harmonia;

      # Configuration derivation
      configDerivation = pkgs.runCommand "harmonia-config" { } ''
        mkdir -p $out/etc/harmonia
        cp ${./config/harmonia.toml} $out/etc/harmonia/harmonia.toml
      '';

      # Build Docker image with harmonia
      harmoniaImage = pkgs.dockerTools.buildLayeredImage {
        name = "harmonia";
        tag = "latest";
        contents = [
          pkgs.bashInteractive
          pkgs.coreutils
          harmoniaPkg
          configDerivation
        ];
        config = {
          Cmd = [
            "${harmoniaPkg}/bin/harmonia"
          ];
          Env = [
            "CONFIG_FILE=/etc/harmonia/harmonia.toml"
          ];
          ExposedPorts = {
            "5000/tcp" = { };
          };
        };
      };
    in
    {
      name = "harmonia";
      containers =
        {
          hostname,
          domain,
          mkTraefikLabels,
          getServiceEnvFiles,
          ...
        }:
        {
          harmonia = {
            image = "harmonia:latest";
            imageFile = harmoniaImage;
            environment = {
              "CONFIG_FILE" = "/etc/harmonia/harmonia.toml";
              "RUST_LOG" = "info,actix_web=debug";
            };
            environmentFiles = getServiceEnvFiles "harmonia";
            volumes = [
              "/data/services/harmonia/data/cache:/nix/store:ro"
              "/data/services/harmonia/keys:/keys:ro"
            ];
            networks = [
              "traefik"
            ];
            labels =
              (mkTraefikLabels {
                name = "harmonia";
                specialSubdomain = "cache";
                port = 5000;
                isPublic = false;
              })
              // {
                "homepage.group" = "Infrastructure";
                "homepage.name" = "Nix Cache";
                "homepage.icon" = "nix";
                "homepage.href" = "http://cache.${domain}";
                "homepage.description" = "Binary cache server";
              };
          };
        };
    };
}
