# Secret Management Flake

This flake provides a generic, declarative secret-management module for NixOS systems running OCI containers. It automatically discovers encrypted `*.age` secret files in arbitrary directories, registers them with `agenix`, and exposes helper functions to inject per-service secrets into container environment variables.

---

## 📦 Inputs

* **`nixpkgs`**: NixOS 24.11 channel
* **`agenix`**: Secret-management library for NixOS

---

## 🚀 How it Works

1. **Directory/Key scanning**: You configure one or more paths under `secretMgmt.secretDirs` and `secretMgmt.publicKeys` respectively (e.g. `./services/firefly/secrets` / `./secrets/host-keys.nix.mahler`).
2. **Secret discovery**: The module uses `builtins.readDir` + `scanDir` to find all `*.age` files.
3. **Secret entries**: Each file is mapped to an `agenix.secrets` entry named `<basedir>-<basename>`, where:
   * `basedir` is the parent directory name (e.g. `myservice`, `myhost`)
   * `basename` is the filename without `.age`
4. **Automatic injection**: Use the helper `lib.getServiceEnvFiles` to generate a list of runtime paths (e.g. `/run/agenix/myservice-db-password`) for a given service name.
5. **OCI integration**: Drop that list into `virtualisation.oci-containers.containers.<name>.environmentFiles` (or `.environment`) to mount or inject your secrets seamlessly.

---

## 🔑 Key & Rekey with YubiKey + `agenix-rekey`

This section shows how to maintain both an unattended host-file key and an offline YubiKey master key.

1. **Generate a host-file identity** (on your server):

```bash
age-keygen -o secrets/host-file-key.txt
```

   * Public key: `age1...filepub`

2. **Generate a YubiKey identity** (offline):

```bash
age-plugin-yubikey -generate
```

   * Public key: `age1...yubikeypub`

3. **Encrypt or rekey a secret**:

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

   * This ensures every `.age` blob is encrypted to both identities.

4. **Store public keys** in `./host-keys.nix`:

```nix
{
  myserver = ["age1...filepub" "age1...yubikeypub"];
}
```
