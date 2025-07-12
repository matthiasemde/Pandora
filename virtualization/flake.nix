{
  description = "Generic virtualization flake: a reusable NixOS module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs =
    { self, ... }:
    {
      nixosModules.default =
        {
          config,
          pkgs,
          lib,
          hostname,
          services,
          getServiceEnvFiles,
          ...
        }:
        let
          mergedContainers = lib.foldl' (
            acc: service:
            let
              maybeContainers =
                if lib.hasAttr "containers" service && builtins.isFunction service.containers then
                  service.containers { inherit hostname getServiceEnvFiles; }
                else
                  { };
            in
            acc // maybeContainers
          ) { } services;

          mergedDependencies = lib.foldl' (
            acc: service:
            let
              deps = service.dependencies or { };
            in
            {
              files = (acc.files or { }) // (deps.files or { });
              networks = (acc.networks or { }) // (deps.networks or { });
            }
          ) { } services;

          # Build a list of file-creation attributes
          fileScripts = lib.mapAttrsToList (file: permissions: {
            name = "create-${lib.escapeShellArg file}-file";
            value = ''
              # Ensure the parent directory exists
              mkdir -p ${dirOf file}
              touch ${file}
              chmod ${permissions} ${file}
            '';
          }) mergedDependencies.files;

          # Build a list of Docker-network-creation attributes
          networkScripts = lib.mapAttrsToList (networkName: opts: {
            name = "create-${networkName}-network";
            value = ''
              # Create Docker network if not exists
              ${pkgs.docker}/bin/docker network inspect ${networkName} >/dev/null 2>&1 || \
              ${pkgs.docker}/bin/docker network create ${opts} ${networkName}
            '';
          }) mergedDependencies.networks;
        in
        {
          # Register activation scripts for file and networks
          system.activationScripts = lib.listToAttrs (fileScripts ++ networkScripts);

          # Declare all containers under oci-containers
          virtualisation.oci-containers = {
            backend = "docker";
            containers = mergedContainers;
          };
        };
    };
}
