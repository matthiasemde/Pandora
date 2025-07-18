# Project Pandora
This repository holds the configuration of my homelab powered by NixOS

```
.
├── cert.pem
├── flake.lock
├── flake.nix
├── hosts
│   └── mahler
│       ├── configuration.nix
│       └── hardware-configuration.nix
├── README.md
├── secret-mgmt
│   ├── add_secret.sh
│   ├── flake.nix
│   └── README.md
├── secrets
│   ├── host-key.nix.mahler
│   └── yubi-key.nix.mahler
├── services
│   ├── adguard
│   │   ├── config
│   │   │   └── AdGuardHome.yaml
│   │   └── flake.nix
│   ├── cloudflared
│   │   ├── config
│   │   │   └── config.yaml
│   │   ├── flake.nix
│   │   └── secrets
│   ├── firefly
│   │   ├── flake.nix
│   │   └── secrets
│   │       ├── app_key.env.age
│   │       ├── app_key.env.age.nix
│   │       ├── gls.json.age
│   │       └── gls.json.age.nix
│   ├── glances
│   │   └── flake.nix
│   ├── home-assistant
│   │   ├── config
│   │   │   ├── automations.yaml
│   │   │   ├── configuration.yaml
│   │   │   ├── scenes.yaml
│   │   │   └── scripts.yaml
│   │   └── flake.nix
│   ├── homepage
│   │   ├── config
│   │   │   ├── bookmarks.yaml
│   │   │   ├── custom.css
│   │   │   ├── custom.js
│   │   │   ├── docker.yaml
│   │   │   ├── services.yaml
│   │   │   ├── settings.yaml
│   │   │   └── widgets.yaml
│   │   ├── flake.nix
│   │   └── README.md
│   ├── nas
│   │   ├── flake.nix
│   │   └── secrets
│   │       ├── fileshare-pw.age
│   │       └── fileshare-pw.age.nix
│   ├── traefik
│   │   ├── config
│   │   │   ├── error.html
│   │   │   ├── nginx.conf
│   │   │   └── traefik.toml
│   │   ├── flake.nix
│   │   └── secrets
│   │       ├── cf-token.env.age
│   │       └── cf-token.env.age.nix
│   └── vscode-server
│       └── flake.nix
├── SETUP.md
└── virtualization
    └── flake.nix
```
