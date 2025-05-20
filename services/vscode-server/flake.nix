{
  description = "Custom VSCode server config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    vscode.url = "github:nix-community/nixos-vscode-server";
  };

  outputs =
    { nixpkgs, vscode, ... }:
    {
      nixosModules.default =
        { config, pkgs, ... }:
        {
          imports = [
            vscode.nixosModules.default
          ];

          services.vscode-server.enable = true;
        };
    };
}
