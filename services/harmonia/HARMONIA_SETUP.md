# Harmonia Binary Cache Setup Summary

## What was created:

1. **Service**: `/home/matthias/infra/services/harmonia/`
   - Nix binary cache server built from nixpkgs
   - Accessible at `http://cache.emdecloud.de` (local only)
   - Serves `/nix/store` over HTTP with signed narinfo files

2. **Deployment Architecture**:
   - **Woodpecker CI**: Builds NixOS closure, pushes to Harmonia
   - **Harmonia**: Caches built artifacts
   - **Webhook Listener**: Host-side service that pulls from cache and activates
   
## Next Steps:

### 1. Generate signing keys:
```bash
sudo mkdir -p /data/services/harmonia/keys
nix-store --generate-binary-cache-key cache.emdecloud.de-1 \
  /data/services/harmonia/keys/cache-priv-key.pem \
  /data/services/harmonia/keys/cache-pub-key.pem
sudo chmod 600 /data/services/harmonia/keys/cache-priv-key.pem
sudo chmod 644 /data/services/harmonia/keys/cache-pub-key.pem
```

### 2. Configure secrets:
```bash
# Harmonia already has .env.age template
agenix -e services/harmonia/.env.age

# Webhook listener needs secret
agenix -e tools/.env.age
# Add: WEBHOOK_SECRET=$(openssl rand -hex 32)
```

### 3. Deploy:
```bash
sudo nixos-rebuild switch --flake .#mahler
```

### 4. Setup webhook listener (systemd service):
```bash
sudo cp tools/webhook-listener.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now webhook-listener.service
```

### 5. Configure Woodpecker to use cache:
Update `.woodpecker/deploy.yaml` with your public key after generating it.

## Files created:
- `/home/matthias/infra/services/harmonia/flake.nix` - Service definition
- `/home/matthias/infra/services/harmonia/config/harmonia.toml` - Configuration
- `/home/matthias/infra/services/harmonia/.env.age` - Secrets template
- `/home/matthias/infra/tools/activate-deployment.sh` - Host activation script
- `/home/matthias/infra/tools/webhook-listener.py` - Webhook service
- `/home/matthias/infra/tools/webhook-listener.service` - Systemd unit
- `/home/matthias/infra/.woodpecker/deploy.yaml` - Updated CI pipeline

## Architecture:
```
GitHub PR merge
    ↓
Woodpecker CI (container)
    → Build NixOS closure
    → Push to Harmonia cache
    → Trigger webhook
    ↓
Webhook Listener (host systemd)
    → Pull from Harmonia
    → Activate system
    → Health checks
```
