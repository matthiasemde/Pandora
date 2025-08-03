{
  description = "A Nix flake to build a Docker image containing the Tailscale Funnel client";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs =
    { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      tailscaleBase = pkgs.dockerTools.pullImage {
        imageName = "tailscale/tailscale";
        imageDigest = "sha256:5d435d256b9b302cb4b40bff2129483a2595e7ac22054c79ad71d3b42986d856";
        sha256 = "sha256-PAiIJvaEjwgsCifgiCSVql+oLpMecwgHCIbLrYFDvGE=";
      };

      # Build custom docker image
      tailscaleImage = pkgs.dockerTools.buildImage {
        name = "tailscale";
        tag = "v1.0.0";
        fromImage = tailscaleBase;

        # Add tailscale and socat
        copyToRoot = pkgs.buildEnv {
          name = "image-root";
          paths = with pkgs; [
            bash
            socat
            curl # used only for debugging
          ];
          pathsToLink = [ "/bin" ];
        };

        config = {
          Entrypoint = [
            "bash"
            "-c"
          ];
          Cmd = [ "/usr/local/bin/containerboot" ];
        };
      };
    in
    {
      name = "tailscale";
      dependencies = {
        networks = {
          "tailscale-ingress" = "";
        };
      };
      containers =
        { hostname, getServiceEnvFiles, ... }:
        {
          tailscale = {
            image = "tailscale:v1.0.0";
            imageFile = tailscaleImage;
            networks = [ "tailscale-ingress" ];
            extraOptions = [ "--dns=1.1.1.1" ];
            environment = {
              "TS_AUTHKEY" = "tskey-auth-kXqwDqnhr521CNTRL-kqfqLEvamaJAcxUE4YEmZJfLmPArLtCZH";
            };
            environmentFiles = getServiceEnvFiles "tailscale";
            labels = {
              # 🛡️ Traefik (disabled)
              "traefik.enable" = "false";
            };
          };
        };
    };
}
