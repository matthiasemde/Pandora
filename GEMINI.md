# Project Pandora: A NixOS-Powered Homelab

## Project Overview

This repository contains the complete configuration for "Project Pandora," a homelab environment managed by NixOS. The project leverages Nix Flakes to provide a declarative and reproducible infrastructure setup. The core of the project is the NixOS configuration, which defines the system state, including services, applications, and user configurations.

The infrastructure is composed of a single host named "mahler" and a variety of services running in Docker containers. Traefik is used as a reverse proxy to expose services to the network, and `agenix` is used for secret management.

## Key Technologies

*   **NixOS:** A Linux distribution that uses a declarative model for system configuration.
*   **Nix Flakes:** A new feature in Nix that improves reproducibility and composability.
*   **Docker:** Used to containerize and run the various services.
*   **Traefik:** A modern reverse proxy and load balancer.
*   **agenix:** A tool for managing secrets in a Nix-based environment.

## Initial Setup

The `SETUP.md` file provides detailed instructions for setting up a new machine with NixOS and deploying this configuration. The high-level steps are:

1.  Install NixOS on the target machine.
2.  Clone this repository.
3.  Run `nixos-rebuild switch --flake .#mahler` to build and apply the configuration.

## Building and Running

After the initial setup, the configuration can be updated by running the same command:

```bash
nixos-rebuild switch --flake .#mahler
```

**Note:** This command should be run from the root of the repository on the "mahler" host.

## Development Conventions

*   **Services as Flakes:** Each service is defined in its own `flake.nix` file within the `services` directory. This promotes modularity and allows for independent management of services.
*   **Containerization:** Services are containerized using Docker. The container definitions are located in the respective service's `flake.nix` file.
*   **Secret Management:** Secrets are managed using `agenix` and are stored in the `secrets` directory. Each service that requires secrets has a corresponding `.age` file.
*   **Configuration:** Service configurations are stored in the `config` directory within each service's directory.

## Coding Style

The `.editorconfig` file defines the coding style for the project. The following are the key conventions:

*   **Indentation:** 2 spaces for all file types.
*   **Character Set:** UTF-8.
*   **Line Endings:** LF.
*   **Whitespace:** Trailing whitespace is trimmed, and a final newline is inserted.

## Virtualization and Container Orchestration

The `virtualization` flake is the heart of the container orchestration. It merges the container definitions from all the services, creates the necessary Docker networks and files, and then defines all the containers for the `oci-containers` backend. This allows for a centralized and declarative way to manage all the containers in the system.

## Secret Management

The `secret-mgmt` flake provides a generic, declarative secret-management module for NixOS systems running OCI containers. It automatically discovers encrypted `*.age` secret files in arbitrary directories, registers them with `agenix`, and exposes helper functions to inject per-service secrets into container environment variables.

### Adding a new secret

1.  Generate a host-file identity (on your server):

    ```bash
    age-keygen -o secrets/host-file-key.txt
    ```

2.  Generate a YubiKey identity (offline):

    ```bash
    age-plugin-yubikey -generate
    ```

3.  Encrypt or rekey a secret:

    ```bash
    # initial encryption
    echo -n "$DB_PASSWORD" \
      | age -o services/myservice/secrets/db-password.age \
          -r age1yld4l2thdgantrknmpe6wdcm9vszjqju98qgjw8cf64frk8lssrskhcxeq \
          -r age1yubikey1qfxert3c6e83vk20ggq70r22pkvu3636cslf4kxa5gdrj900hqf2qaxhcfa

    # rekey later (rotations, add/remove recipients)
    agenix-rekey -i age-plugin-yubikey \
      services/myservice/secrets/db-password.age
    ```

4.  Store public keys in `./host-keys.nix`:

    ```nix
    {
      myserver = ["age1...filepub" "age1...yubikeypub"];
    }
    ```

## Ignored Files

The `.gitignore` file is configured to ignore a variety of files and directories, including:

*   Nix build artifacts
*   Editor/IDE files
*   Logs
*   Docker-related files
*   Secrets
*   Systemd runtime links
*   Miscellaneous temporary files

## Service-Specific Notes

### Homepage

To generate a password for the `homepage` service, you can use the following command:

```bash
nix-shell -p apacheHttpd --run "htpasswd -n thema"
```

### Kopia

To connect a client to the Kopia server, you can use the following commands:

```bash
./kopia repository connect server --url=https://kopia.emdecloud.de:443  --override-username=matthias --override-hostname=vogel

./kopia repository connect server --url=https://kopia.mahler.local:443  --override-username=matthias --override-hostname=vogel --server-cert-fingerprint 60A5E430E21A41EA738CA1F86D76EB70330905480902F973C1659059257A825D
```

### Nextcloud

To build the Nextcloud docker image, you can use the following command:

```bash
docker build -t nextcloud-derived:v1.1.1 .
```

### Radicale

To add users to the Radicale service, you can use the following commands:

```bash
nix shell nixpkgs#apacheHttpd
htpasswd -5 -c ./services/radicale/users newuser
```