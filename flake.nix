{
  description = "Top level flake for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Local flakes
    vscode-server.url = "./services/vscode-server";
    virtualization.url = "./virtualization";
  };

  outputs =
    {
      self,
      nixpkgs,
      vscode-server,
      virtualization,
      ...
    }:
    {
      nixosConfigurations.mahler = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./hosts/mahler/configuration.nix

          vscode-server.nixosModules.default
          virtualization.nixosModules.default
        ];

        specialArgs = {
          hostname = "mahler";
          services = [ ];
        };
      };
    };
}
