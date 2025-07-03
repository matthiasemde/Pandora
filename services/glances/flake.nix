{
  outputs =
    { ... }:
    {
      name = "glances";
      networks = {
        "glances" = "";
      };
      containers =
        { ... }:
        {
          glances = {
            image = "nicolargo/glances:4.3.1";
            networks = [ "glances" ];
            volumes = [
              "/var/run/docker.sock:/var/run/docker.sock"
              "/etc/os-release:/etc/os-release:ro"
            ];
            environment = {
              GLANCES_OPT = "-w";
            };
            labels = {
              # Traefik (disabled)
              "traefik.enable" = "false";
            };
          };
        };
    };
}
