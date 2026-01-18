# Harmonia - Nix Binary Cache

Harmonia is a Nix binary cache server that serves pre-built packages and system closures.

## Setup

### 1. Generate signing keys

```bash
# Create directory for keys
sudo mkdir -p /data/services/harmonia/keys

# Generate cache signing key
nix-store --generate-binary-cache-key cache.emdecloud.de-1 \
  /data/services/harmonia/keys/cache-priv-key.pem \
  /data/services/harmonia/keys/cache-pub-key.pem

# Set permissions
sudo chmod 600 /data/services/harmonia/keys/cache-priv-key.pem
sudo chmod 644 /data/services/harmonia/keys/cache-pub-key.pem

# Save the public key for later
cat /data/services/harmonia/keys/cache-pub-key.pem
```

### 2. Configure secrets

```bash
agenix -e services/harmonia/.env.age
```

### 3. Add to flake.nix

Add harmonia to your main flake.nix inputs and services list.

### 4. Rebuild

```bash
sudo nixos-rebuild switch --flake .#mahler
```

### 5. Test the cache

```bash
curl http://cache.emdecloud.de/nix-cache-info
```

## Usage in CI/CD

In Woodpecker pipeline:
```bash
nix copy --to http://harmonia:5000 ./result
```
