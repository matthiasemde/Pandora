# Project Pandora
This repository holds the configuration of my homelab powered by NixOS
<!-- DIRECTORY_STRUCTURE_START -->

```
.
├── .editorconfig
├── flake.lock
├── flake.nix
├── .gitignore
├── hosts
│   └── mahler
│       ├── configuration.nix
│       └── hardware-configuration.nix
├── README.md
├── secret-mgmt
│   ├── add_secret.sh
│   ├── flake.nix
│   └── README.md
├── secrets
│   ├── host-key.nix.mahler
│   └── yubi-key.nix.mahler
├── services
│   ├── adguard
│   │   ├── config
│   │   │   └── AdGuardHome.yaml
│   │   └── flake.nix
│   ├── firefly
│   │   ├── .db.env
│   │   ├── .env
│   │   ├── flake.nix
│   │   └── secrets
│   │       ├── .env.age
│   │       └── .env.age.nix
│   ├── homepage
│   │   ├── config
│   │   │   ├── bookmarks.yaml
│   │   │   ├── custom.css
│   │   │   ├── custom.js
│   │   │   ├── docker.yaml
│   │   │   ├── services.yaml
│   │   │   ├── settings.yaml
│   │   │   └── widgets.yaml
│   │   ├── flake.nix
│   │   └── README.md
│   ├── traefik
│   │   └── flake.nix
│   └── vscode-server
│       └── flake.nix
├── SETUP.md
└── virtualization
    └── flake.nix

15 directories, 32 files
```

<!-- DIRECTORY_STRUCTURE_END -->
