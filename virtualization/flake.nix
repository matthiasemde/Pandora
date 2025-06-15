{
  description = "Virtualization flake for mahler homelab";

  inputs = {
    nixpkgs.url        = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url    = "github:numtide/flake-utils";
    homepage.url       = "path:../services/homepage";
    traefik.url        = "path:../services/traefik";
  };

  outputs = { self, nixpkgs, flake-utils, homepage, traefik, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in {
        nixosConfigurations.mahler = pkgs.lib.nixosSystem {
          system = system;
          modules = [
            ./configuration.nix
            homepage.nixosModule
            traefik.nixosModule
          ];
        };
      });
}
