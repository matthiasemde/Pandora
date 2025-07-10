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
│   ├── firefly
│   │   ├── flake.nix
│   │   └── secrets
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
│   ├── traefik
│   │   └── flake.nix
│   └── vscode-server
│       └── flake.nix
├── SETUP.md
└── virtualization
    └── flake.nix
```
