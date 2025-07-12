{
  description = "Top level flake for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Local flakes
    ## Utilities
    vscode-server.url = "path:./services/vscode-server";
    agenix.url = "github:ryantm/agenix";
    secret-mgmt.url = "path:./secret-mgmt";

    ## Virtualization / Services
    virtualization.url = "path:./virtualization";
    homepage.url = "path:./services/homepage";
    glances.url = "path:./services/glances";
    traefik.url = "path:./services/traefik";
    cloudflared.url = "path:./services/cloudflared";
    adguard.url = "path:./services/adguard";
    firefly.url = "path:./services/firefly";
    home-assistant.url = "path:./services/home-assistant";
    nas.url = "path:./services/nas";
  };

  outputs =
    {
      self,
      nixpkgs,
      vscode-server,
      virtualization,
      homepage,
      glances,
      traefik,
      cloudflared,
      adguard,
      agenix,
      secret-mgmt,
      firefly,
      home-assistant,
      nas,
      ...
    }:
    {
      nixosConfigurations.mahler = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./hosts/mahler/configuration.nix

          vscode-server.nixosModules.default
          agenix.nixosModules.default
          {
            environment.systemPackages = [ agenix.packages.x86_64-linux.default ];
            age.identityPaths = [ "/home/matthias/infra/secrets/host-key.nix.mahler" ];
          }

          secret-mgmt.nixosModules.default
          virtualization.nixosModules.default
          nas.nixosModules.default
        ];

        specialArgs = {
          hostname = "mahler";
          services = [
            homepage
            glances
            traefik
            cloudflared
            adguard
            firefly
            home-assistant
            nas
          ];
          getServiceEnvFiles = secret-mgmt.lib.getServiceEnvFiles;
          getServiceSecrets = secret-mgmt.lib.getServiceSecrets;
        };
      };
    };
}
