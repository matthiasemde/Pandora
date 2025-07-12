{
  description = "NAS configuration using Samba";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs =
    { nixpkgs, ... }:
    {
      name = "nas";
      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          getServiceSecrets,
          ...
        }:
        let
          shareUser = "fileshare";
          shareUserPasswordFile = builtins.head (getServiceSecrets "nas");
          nasStoragePath = "/data/services/nas";
        in
        {
          users.users.${shareUser} = {
            isSystemUser = true;
            group = "users";
          };

          systemd.tmpfiles.rules = [
            "d ${nasStoragePath} 0770 ${shareUser} users -"
          ];

          services.samba = {
            enable = true;
            openFirewall = true;
            package = pkgs.samba;
            settings = {
              global = {
                security = "user";
                "map to guest" = "Bad User";
              };
              fileshare = {
                path = nasStoragePath;
                "read only" = "no";
                "guest ok" = "no";
                "valid users" = [ shareUser ];
              };
            };
          };

          system.activationScripts.nas-set-samba-password.text = ''
            echo "Setting Samba password for ${shareUser} from ${shareUserPasswordFile}"
            ${pkgs.coreutils}/bin/cat ${shareUserPasswordFile} ${shareUserPasswordFile} | \
            ${pkgs.samba}/bin/smbpasswd -s -a ${shareUser}
          '';
        };
    };
}
