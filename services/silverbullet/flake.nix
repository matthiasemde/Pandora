{
  description = "Service flake for Silver Bullet";

  outputs =
    { self, nixpkgs }:
    {
      name = "silverbullet";
      containers =
        {
          domain,
          mkTraefikLabels,
          ...
        }:
        {
          silverbullet = {
            rawImageReference = "ghcr.io/silverbulletmd/silverbullet:2.5.1@sha256:acb9c08cea39e963a5428f3db5aa4967137a65c1446405a4ba26df4d23884f73";
            nixSha256 = "sha256-T0ziLBxLzF0wKOjg0+IdQQLkDbifhDUut27vDfYYn4o=";
            networks = [ "traefik" ];
            volumes = [
              "/data/services/silverbullet/space:/space"
            ];
            labels =
              mkTraefikLabels {
                name = "silverbullet";
                port = "3000";
                useForwardAuth = true;
              }
              // {
                "homepage.group" = "Life Management";
                "homepage.name" = "Silverbullet";
                "homepage.icon" = "silverbullet";
                "homepage.href" = "https://silverbullet.${domain}";
                "homepage.description" = "Personal knowledge management";
              };
          };
        };
    };
}
