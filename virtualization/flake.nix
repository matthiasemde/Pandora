{
  description = "Generic virtualization flake: a reusable NixOS module";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosModules.default = import ./configuration.nix;
  };
}
