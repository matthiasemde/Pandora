{
  description = "Top level flake for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Local flakes
    vscode-server.url = "path:./services/vscode-server";
    virtualization.url = "path:./virtualization";
    homepage.url = "path:./services/homepage";
    traefik.url = "path:./services/traefik";
    adguard.url = "path:./services/adguard";
  };

  outputs =
    {
      self,
      nixpkgs,
      vscode-server,
      virtualization,
      homepage,
      traefik,
      adguard,
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
          services = [
            homepage
            traefik
            adguard
          ];
        };
      };
    };
}
