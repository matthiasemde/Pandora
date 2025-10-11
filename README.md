# Project Pandora
This repository holds the configuration of my homelab powered by NixOS

## Directory Structure

The directory structure is automatically updated by a pre-commit hook. See the [Pre-Commit Hook Setup](#pre-commit-hook-setup) section below for installation instructions.

<!-- DIRECTORY_STRUCTURE_START -->

```
.
|-- .editorconfig
|-- .gitignore
|-- GEMINI.md
|-- README.md
|-- SETUP.md
|-- flake.lock
|-- flake.nix
|-- hosts
|   `-- mahler
|       |-- configuration.nix
|       `-- hardware-configuration.nix
|-- install-precommit-hook.sh
|-- pre-commit-hook.sh
|-- renovate.json
|-- secret-mgmt
|   |-- README.md
|   |-- add_secret.sh
|   `-- flake.nix
|-- services
|   |-- adguard
|   |   |-- config
|   |   |   `-- AdGuardHome.yaml
|   |   `-- flake.nix
|   |-- authentik
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- AUTHENTIK_SECRET_KEY.env.age
|   |       |-- AUTHENTIK_SECRET_KEY.env.age.nix
|   |       |-- db-credentials.env.age
|   |       |-- db-credentials.env.age.nix
|   |       |-- smtp-credentials.env.age
|   |       `-- smtp-credentials.env.age.nix
|   |-- cloudflared
|   |   |-- config
|   |   |   `-- config.yaml
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- .env.age
|   |       `-- .env.age.nix
|   |-- firefly
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- app_key.env.age
|   |       |-- app_key.env.age.nix
|   |       |-- gls-tagesgeldkonto.json.age
|   |       |-- gls-tagesgeldkonto.json.age.nix
|   |       |-- gls.json.age
|   |       `-- gls.json.age.nix
|   |-- frp
|   |   |-- .env
|   |   |-- config
|   |   |   `-- frpc.toml
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- FRP_TOKEN.env.age
|   |       `-- FRP_TOKEN.env.age.nix
|   |-- glances
|   |   `-- flake.nix
|   |-- home-assistant
|   |   |-- config
|   |   |   |-- automations.yaml
|   |   |   |-- configuration.yaml
|   |   |   |-- scenes.yaml
|   |   |   `-- scripts.yaml
|   |   `-- flake.nix
|   |-- homepage
|   |   |-- README.md
|   |   |-- config
|   |   |   |-- bookmarks.yaml
|   |   |   |-- custom.css
|   |   |   |-- custom.js
|   |   |   |-- docker.yaml
|   |   |   |-- services.yaml
|   |   |   |-- settings.yaml
|   |   |   `-- widgets.yaml
|   |   `-- flake.nix
|   |-- immich
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- DB_PASSWORD.env.age
|   |       |-- DB_PASSWORD.env.age.nix
|   |       |-- POSTGRES_PASSWORD.env.age
|   |       `-- POSTGRES_PASSWORD.env.age.nix
|   |-- kopia
|   |   |-- README.md
|   |   |-- create_repository.sh
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- KOPIA_PASSWORD.env.age
|   |       |-- KOPIA_PASSWORD.env.age.nix
|   |       |-- KOPIA_SERVER_CONTROL_CREDENTIALS.env.age
|   |       |-- KOPIA_SERVER_CONTROL_CREDENTIALS.env.age.nix
|   |       |-- KOPIA_SERVER_CREDENTIALS.env.age
|   |       `-- KOPIA_SERVER_CREDENTIALS.env.age.nix
|   |-- nas
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- fileshare-pw.age
|   |       `-- fileshare-pw.age.nix
|   |-- nextcloud
|   |   |-- Dockerfile
|   |   |-- README.md
|   |   |-- flake.nix
|   |   |-- secrets
|   |   |   |-- NEXTCLOUD_ADMIN_PASSWORD.env.age
|   |   |   |-- NEXTCLOUD_ADMIN_PASSWORD.env.age.nix
|   |   |   |-- POSTGRES_PASSWORD.env.age
|   |   |   `-- POSTGRES_PASSWORD.env.age.nix
|   |   `-- supervisord.conf
|   |-- paperless
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- PAPERLESS_SECRET_KEY.env.age
|   |       |-- PAPERLESS_SECRET_KEY.env.age.nix
|   |       |-- smtp-credentials.env.age
|   |       `-- smtp-credentials.env.age.nix
|   |-- pterodactyl
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- db_credentials.env.age
|   |       |-- db_credentials.env.age.nix
|   |       |-- smtp_credentials.env.age
|   |       `-- smtp_credentials.env.age.nix
|   |-- radicale
|   |   |-- README.md
|   |   |-- config
|   |   |   `-- config
|   |   |-- flake.nix
|   |   `-- users
|   |-- traefik
|   |   |-- config
|   |   |   |-- error.html
|   |   |   |-- nginx.conf
|   |   |   `-- traefik.toml
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- cf-token.env.age
|   |       `-- cf-token.env.age.nix
|   |-- vaultwarden
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- ADMIN_TOKEN.env.age
|   |       |-- ADMIN_TOKEN.env.age.nix
|   |       |-- smtp-credentials.env.age
|   |       `-- smtp-credentials.env.age.nix
|   `-- vscode-server
|       `-- flake.nix
`-- virtualization
    `-- flake.nix

43 directories, 107 files
```

<!-- DIRECTORY_STRUCTURE_END -->

## Pre-Commit Hook Setup

This repository includes a pre-commit hook that automatically updates the directory structure in this README file whenever you make a commit. This ensures the documentation always reflects the current state of the repository.

### Installation

To install the pre-commit hook, run the following command from the repository root:

```bash
./install-precommit-hook.sh
```

This will:
- Copy the pre-commit hook to `.git/hooks/pre-commit`
- Make the hook executable
- Provide feedback on the installation status

### Requirements

The pre-commit hook requires the `tree` command to be installed. 

**On NixOS**, you can install it by adding `tree` to your system packages, or run it temporarily:

```bash
nix-shell -p tree
```

**On other systems**, install tree using your package manager:
- Ubuntu/Debian: `sudo apt install tree`
- macOS: `brew install tree`
- Fedora/RHEL: `sudo dnf install tree`

### How It Works

- The hook automatically runs before each commit
- It generates a fresh directory structure using the `tree` command
- The structure is inserted between the `<!-- DIRECTORY_STRUCTURE_START -->` and `<!-- DIRECTORY_STRUCTURE_END -->` markers

```
.
|-- .editorconfig
|-- .gitignore
|-- GEMINI.md
|-- README.md
|-- SETUP.md
|-- flake.lock
|-- flake.nix
|-- hosts
|   `-- mahler
|       |-- configuration.nix
|       `-- hardware-configuration.nix
|-- install-precommit-hook.sh
|-- pre-commit-hook.sh
|-- renovate.json
|-- secret-mgmt
|   |-- README.md
|   |-- add_secret.sh
|   `-- flake.nix
|-- services
|   |-- adguard
|   |   |-- config
|   |   |   `-- AdGuardHome.yaml
|   |   `-- flake.nix
|   |-- authentik
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- AUTHENTIK_SECRET_KEY.env.age
|   |       |-- AUTHENTIK_SECRET_KEY.env.age.nix
|   |       |-- db-credentials.env.age
|   |       |-- db-credentials.env.age.nix
|   |       |-- smtp-credentials.env.age
|   |       `-- smtp-credentials.env.age.nix
|   |-- cloudflared
|   |   |-- config
|   |   |   `-- config.yaml
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- .env.age
|   |       `-- .env.age.nix
|   |-- firefly
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- app_key.env.age
|   |       |-- app_key.env.age.nix
|   |       |-- gls-tagesgeldkonto.json.age
|   |       |-- gls-tagesgeldkonto.json.age.nix
|   |       |-- gls.json.age
|   |       `-- gls.json.age.nix
|   |-- frp
|   |   |-- .env
|   |   |-- config
|   |   |   `-- frpc.toml
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- FRP_TOKEN.env.age
|   |       `-- FRP_TOKEN.env.age.nix
|   |-- glances
|   |   `-- flake.nix
|   |-- home-assistant
|   |   |-- config
|   |   |   |-- automations.yaml
|   |   |   |-- configuration.yaml
|   |   |   |-- scenes.yaml
|   |   |   `-- scripts.yaml
|   |   `-- flake.nix
|   |-- homepage
|   |   |-- README.md
|   |   |-- config
|   |   |   |-- bookmarks.yaml
|   |   |   |-- custom.css
|   |   |   |-- custom.js
|   |   |   |-- docker.yaml
|   |   |   |-- services.yaml
|   |   |   |-- settings.yaml
|   |   |   `-- widgets.yaml
|   |   `-- flake.nix
|   |-- immich
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- DB_PASSWORD.env.age
|   |       |-- DB_PASSWORD.env.age.nix
|   |       |-- POSTGRES_PASSWORD.env.age
|   |       `-- POSTGRES_PASSWORD.env.age.nix
|   |-- kopia
|   |   |-- README.md
|   |   |-- create_repository.sh
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- KOPIA_PASSWORD.env.age
|   |       |-- KOPIA_PASSWORD.env.age.nix
|   |       |-- KOPIA_SERVER_CONTROL_CREDENTIALS.env.age
|   |       |-- KOPIA_SERVER_CONTROL_CREDENTIALS.env.age.nix
|   |       |-- KOPIA_SERVER_CREDENTIALS.env.age
|   |       `-- KOPIA_SERVER_CREDENTIALS.env.age.nix
|   |-- nas
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- fileshare-pw.age
|   |       `-- fileshare-pw.age.nix
|   |-- nextcloud
|   |   |-- Dockerfile
|   |   |-- README.md
|   |   |-- flake.nix
|   |   |-- secrets
|   |   |   |-- NEXTCLOUD_ADMIN_PASSWORD.env.age
|   |   |   |-- NEXTCLOUD_ADMIN_PASSWORD.env.age.nix
|   |   |   |-- POSTGRES_PASSWORD.env.age
|   |   |   `-- POSTGRES_PASSWORD.env.age.nix
|   |   `-- supervisord.conf
|   |-- paperless
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- PAPERLESS_SECRET_KEY.env.age
|   |       |-- PAPERLESS_SECRET_KEY.env.age.nix
|   |       |-- smtp-credentials.env.age
|   |       `-- smtp-credentials.env.age.nix
|   |-- pterodactyl
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- db_credentials.env.age
|   |       |-- db_credentials.env.age.nix
|   |       |-- smtp_credentials.env.age
|   |       `-- smtp_credentials.env.age.nix
|   |-- radicale
|   |   |-- README.md
|   |   |-- config
|   |   |   `-- config
|   |   |-- flake.nix
|   |   `-- users
|   |-- traefik
|   |   |-- config
|   |   |   |-- error.html
|   |   |   |-- nginx.conf
|   |   |   `-- traefik.toml
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- cf-token.env.age
|   |       `-- cf-token.env.age.nix
|   |-- vaultwarden
|   |   |-- flake.nix
|   |   `-- secrets
|   |       |-- ADMIN_TOKEN.env.age
|   |       |-- ADMIN_TOKEN.env.age.nix
|   |       |-- smtp-credentials.env.age
|   |       `-- smtp-credentials.env.age.nix
|   `-- vscode-server
|       `-- flake.nix
`-- virtualization
    `-- flake.nix

43 directories, 107 files
```

