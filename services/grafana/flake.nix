{
  description = "Grafana + Prometheus monitoring stack service flake";

  outputs =
    { self, nixpkgs }:
    {
      name = "grafana";
      dependencies = {
        networks = {
          "monitoring" = "";
        };
      };
      containers =
        {
          hostname,
          domain,
          parseDockerImageReference,
          mkTraefikLabels,
          getServiceEnvFiles,
          ...
        }:
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          # Grafana
          grafanaRawImageReference = "grafana/grafana:12.3.0@sha256:e68a7df1a54586485a83d826740b36964df54b3a2a87c114b6d6989a24a7dd39";
          grafanaImageReference = parseDockerImageReference grafanaRawImageReference;
          grafanaImage = pkgs.dockerTools.pullImage {
            imageName = grafanaImageReference.name;
            imageDigest = grafanaImageReference.digest;
            finalImageTag = grafanaImageReference.tag;
            sha256 = "sha256-uv2yeV6wv0jXETt524HbeWvPJTkxmezP6EBECd8FR0Q=";
          };

          # Prometheus
          prometheusRawImageReference = "prom/prometheus:v3.7.2@sha256:23031bfe0e74a13004252caaa74eccd0d62b6c6e7a04711d5b8bf5b7e113adc7";
          prometheusImageReference = parseDockerImageReference prometheusRawImageReference;
          prometheusImage = pkgs.dockerTools.pullImage {
            imageName = prometheusImageReference.name;
            imageDigest = prometheusImageReference.digest;
            finalImageTag = prometheusImageReference.tag;
            sha256 = "sha256-ynV+H5zJ5yQ0hJPnfERtDdkf8LT9IQWwBIMbYozJJbk=";
          };
        in
        {
          grafana = {
            image = grafanaImageReference.name + ":" + grafanaImageReference.tag;
            imageFile = grafanaImage;
            networks = [
              "monitoring"
              "traefik"
            ];
            environmentFiles = getServiceEnvFiles "grafana";
            volumes = [
              "/data/services/grafana/grafana:/var/lib/grafana"
              "${./config/datasources.yml}:/etc/grafana/provisioning/datasources/datasources.yml:ro"
            ];
            environment = {
              GF_SECURITY_DISABLE_INITIAL_ADMIN_CREATION = "true"; # login via authentik

              # SMTP configuration for notifications
              GF_SMTP_ENABLED = "true";
              GF_SMTP_HOST = "mail.privateemail.com:465";
              # GF_SMTP_USER = ""; # set via secret-mgmt
              # GF_SMTP_PASSWORD = ""; # set via secret-mgmtr
              GF_SMTP_FROM_ADDRESS = "no-reply@emdecloud.de";
              GF_SMTP_FROM_NAME = "Grafana";

              # Authentik config
              GF_AUTH_GENERIC_OAUTH_ENABLED = "true";
              GF_AUTH_GENERIC_OAUTH_NAME = "authentik";
              GF_AUTH_GENERIC_OAUTH_CLIENT_ID = "E0ryu0936Q62OLtR4W1DHdPjz87RtJp3Jn2pWb27";
              # GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = "<Client Secret>"; # set via secret-mgmt
              GF_AUTH_GENERIC_OAUTH_SCOPES = "openid profile email";
              GF_AUTH_GENERIC_OAUTH_AUTH_URL = "https://auth.${domain}/application/o/authorize/";
              GF_AUTH_GENERIC_OAUTH_TOKEN_URL = "https://auth.${domain}/application/o/token/";
              GF_AUTH_GENERIC_OAUTH_API_URL = "https://auth.${domain}/application/o/userinfo/";
              GF_AUTH_SIGNOUT_REDIRECT_URL = "https://auth.${domain}/application/o/grafana/end-session/";
              # Optionally enable auto-login (bypasses Grafana login screen)
              GF_AUTH_OAUTH_AUTO_LOGIN = "true";
              # Optionally map user groups to Grafana roles
              GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH = "contains(groups[*], 'admins') && 'Admin' || 'Viewer'";
              # Required if Grafana is running behind a reverse proxy
              GF_SERVER_ROOT_URL = "https://grafana.${domain}";
            };
            labels =
              (mkTraefikLabels {
                name = "grafana";
                port = "3000";
              })
              // {
                "homepage.group" = "Monitoring";
                "homepage.name" = "Grafana";
                "homepage.icon" = "grafana";
                "homepage.href" = "https://grafana.${domain}";
                "homepage.description" = "Metrics visualization and dashboards";
              };
          };

          prometheus = {
            image = prometheusImageReference.name + ":" + prometheusImageReference.tag;
            imageFile = prometheusImage;
            networks = [
              "monitoring"
              "traefik"
            ];
            volumes = [
              "/data/services/grafana/prometheus:/prometheus"
              "${./config/prometheus.yml}:/etc/prometheus/prometheus.yml:ro"
            ];
            cmd = [
              "--config.file=/etc/prometheus/prometheus.yml"
              "--storage.tsdb.path=/prometheus"
              "--web.console.libraries=/etc/prometheus/console_libraries"
              "--web.console.templates=/etc/prometheus/consoles"
              "--storage.tsdb.retention.time=30d"
              "--web.enable-lifecycle"
              "--web.enable-admin-api"
              "--web.listen-address=0.0.0.0:9090"
            ];
            labels =
              (mkTraefikLabels {
                name = "prometheus";
                port = "9090";
                isPublic = false;
              })
              // {

                "homepage.group" = "Monitoring";
                "homepage.name" = "Prometheus";
                "homepage.icon" = "prometheus";
                "homepage.href" = "http://prometheus.${hostname}.local";
                "homepage.description" = "Metrics collection and storage";
              };
          };
        };
    };
}
