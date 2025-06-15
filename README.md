# Project Pandora
This repository holds the configuration of my homelab powered by NixOS

```
.
├── flake.lock
├── flake.nix
├── hosts
│   └── mahler
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       └── secrets
├── README.md
├── secrets
│   ├── host-key.nix.mahler
│   └── yubi-key.nix.mahler
├── services
│   ├── homepage
│   │   ├── config
│   │   │   ├── bookmarks.yaml
│   │   │   ├── custom.css
│   │   │   ├── custom.js
│   │   │   ├── docker.yaml
│   │   │   ├── services.yaml
│   │   │   ├── settings.yaml
│   │   │   └── widgets.yaml
│   │   └── flake.nix
│   ├── traefik
│   │   └── flake.nix
│   └── vscode-server
│       └── flake.nix
├── SETUP.md
└── virtualization
    └── flake.nix
```
