# Matrix Synapse Service

This directory contains the NixOS configuration for the Matrix Synapse homeserver.

## Architecture

The service consists of three containers:
- **synapse-app**: The main Matrix Synapse server
- **synapse-db**: PostgreSQL database for persistent storage
- **synapse-redis**: Redis for caching and replication

## Configuration

### Main Configuration
- `config/homeserver.yaml`: Main Synapse configuration file
- `config/log.config`: Logging configuration

### Secrets
The following secrets need to be generated and encrypted using agenix:

1. **POSTGRES_PASSWORD.env.age**: PostgreSQL database password
   ```bash
   echo "POSTGRES_PASSWORD=your-secure-password" | age -r age1yld4l2thdgantrknmpe6wdcm9vszjqju98qgjw8cf64frk8lssrskhcxeq -r age1yubikey1qfxert3c6e83vk20ggq70r22pkvu3636cslf4kxa5gdrj900hqf2qaxhcfa -o secrets/POSTGRES_PASSWORD.env.age
   ```

2. **SYNAPSE_REGISTRATION_SHARED_SECRET.env.age**: For registering users via the API
   ```bash
   # Generate a random secret
   SECRET=$(openssl rand -hex 32)
   echo "SYNAPSE_REGISTRATION_SHARED_SECRET=$SECRET" | age -r age1yld4l2thdgantrknmpe6wdcm9vszjqju98qgjw8cf64frk8lssrskhcxeq -r age1yubikey1qfxert3c6e83vk20ggq70r22pkvu3636cslf4kxa5gdrj900hqf2qaxhcfa -o secrets/SYNAPSE_REGISTRATION_SHARED_SECRET.env.age
   ```

3. **SYNAPSE_MACAROON_SECRET_KEY.env.age**: For generating access tokens
   ```bash
   SECRET=$(openssl rand -hex 32)
   echo "SYNAPSE_MACAROON_SECRET_KEY=$SECRET" | age -r age1yld4l2thdgantrknmpe6wdcm9vszjqju98qgjw8cf64frk8lssrskhcxeq -r age1yubikey1qfxert3c6e83vk20ggq70r22pkvu3636cslf4kxa5gdrj900hqf2qaxhcfa -o secrets/SYNAPSE_MACAROON_SECRET_KEY.env.age
   ```

4. **SYNAPSE_FORM_SECRET.env.age**: For securing forms
   ```bash
   SECRET=$(openssl rand -hex 32)
   echo "SYNAPSE_FORM_SECRET=$SECRET" | age -r age1yld4l2thdgantrknmpe6wdcm9vszjqju98qgjw8cf64frk8lssrskhcxeq -r age1yubikey1qfxert3c6e83vk20ggq70r22pkvu3636cslf4kxa5gdrj900hqf2qaxhcfa -o secrets/SYNAPSE_FORM_SECRET.env.age
   ```

## Traefik Integration

The service is configured with two routers:
- **synapse-client**: Client API on `https://matrix.mahler.local` (port 8008)
- **synapse-federation**: Federation API on `https://synapse.mahler.local` (port 8448)

## Data Storage

The service stores data in the following locations:
- `/data/services/synapse/db`: PostgreSQL database
- `/data/services/synapse/redis`: Redis persistence
- `/data/services/synapse/data`: Synapse data including media store and signing keys

## TODOs

### Required Setup Steps

- [ ] **Generate and encrypt all required secrets** (see Secrets section above)
- [ ] **Create data directories**:
  ```bash
  sudo mkdir -p /data/services/synapse/{db,redis,data/media_store,data/keys}
  sudo chown -R 991:991 /data/services/synapse/data  # Synapse runs as UID 991
  ```

- [ ] **Configure database connection**: Ensure the database password is properly encrypted and available

- [ ] **Generate signing keys**: On first run, Synapse will auto-generate signing keys in `/data/services/synapse/data/keys/`

### DNS Configuration

- [ ] **Set up DNS entries** for federation to work properly:
  - `matrix.mahler.local` → Internal IP
  - `synapse.mahler.local` → Internal IP
  - For external federation, you'll need public DNS entries and proper port forwarding

- [ ] **Configure SRV records** (if using federation):
  ```
  _matrix._tcp.mahler.local. 3600 IN SRV 10 0 8448 synapse.mahler.local.
  ```

### Client Registration

- [ ] **Configure registration settings** in `config/homeserver.yaml`:
  - Set `enable_registration: true` if you want open registration
  - Or use the registration shared secret to register users manually

- [ ] **Register the first admin user**:
  ```bash
  docker exec -it synapse-app register_new_matrix_user -c /data/homeserver.yaml -u admin -p password -a http://localhost:8008
  ```

### Optional Enhancements

- [ ] **Configure SMTP** for email notifications (see homeserver.yaml)
- [ ] **Set up TURN server** for VoIP functionality
- [ ] **Configure media retention policies** to manage storage
- [ ] **Enable metrics** for monitoring with Prometheus
- [ ] **Configure room directory** and federation settings
- [ ] **Set up rate limiting** according to your needs
- [ ] **Configure CORS** if needed for web clients

### Security Configuration

- [ ] **Review and adjust rate limiting** settings in homeserver.yaml
- [ ] **Configure allowed federation domains** (whitelist/blacklist)
- [ ] **Set up proper firewall rules** for federation (port 8448)
- [ ] **Review security settings** in the Synapse documentation
- [ ] **Set up regular backups** of the database and media store

## Federation

For federation to work properly with other Matrix homeservers:

1. Your server must be reachable on port 8448 (or you must configure delegation)
2. DNS must be properly configured with SRV records
3. TLS certificates must be valid for the domain
4. The server_name in homeserver.yaml should match your domain

## Useful Commands

### Creating Users
```bash
# Interactive user creation
docker exec -it synapse-app register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008

# Using shared secret
curl -X POST -H "Content-Type: application/json" \
  -d '{"username":"myuser","password":"mypassword","admin":false,"shared_secret":"YOUR_REGISTRATION_SHARED_SECRET"}' \
  https://matrix.mahler.local/_synapse/admin/v1/register
```

### Database Access
```bash
docker exec -it synapse-db psql -U synapse
```

### Logs
```bash
docker logs synapse-app
docker logs synapse-db
docker logs synapse-redis
```

## References

- [Synapse Documentation](https://matrix-org.github.io/synapse/latest/)
- [Configuration Documentation](https://matrix-org.github.io/synapse/latest/usage/configuration/config_documentation.html)
- [Federation Tester](https://federationtester.matrix.org/)
- [Matrix Specification](https://spec.matrix.org/)
