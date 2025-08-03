socat TCP-LISTEN:80,fork TCP:traefik:80
socat TCP-LISTEN:443,fork TCP:traefik:443

tailscale funnel http://localhost:80
tailscale funnel https://localhost:443

