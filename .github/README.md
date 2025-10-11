# GitHub Actions Workflows

## Update Docker Image SHA256 Hashes

### Overview

The `update-docker-hashes.yml` workflow automatically updates the SHA256 hashes for Docker images in service flake files whenever Renovate creates or updates a pull request.

### How It Works

1. **Trigger**: The workflow runs when a pull request with a title starting with `chore(deps)` is opened, synchronized (updated), or reopened.

2. **Process**:
   - Checks out the PR branch
   - Installs Nix with flakes support
   - Scans all `services/*/flake.nix` files for Docker image references
   - For each image found:
     - Extracts the image name, tag, and digest from `*RawImageReference` variables
     - Uses `nix-prefetch-docker` to fetch the correct Nix SHA256 hash for the image
     - Compares the fetched hash with the current hash in the file
     - Updates the hash if it differs
   - Commits and pushes the changes back to the PR branch if any hashes were updated

3. **Permissions**: The workflow has `contents: write` permission to push changes to the PR branch.

### Why This Is Needed

Renovate bot can update Docker image digests in the `*RawImageReference` lines but cannot automatically update the corresponding `sha256` hashes required by Nix's `dockerTools.pullImage`. This workflow bridges that gap by:

- Automatically fetching the correct Nix hash for each updated image
- Ensuring builds don't fail due to hash mismatches
- Reducing manual work for maintainers

### Example

When Renovate updates an image reference like:

```nix
glancesRawImageReference = "nicolargo/glances:4.3.3@sha256:abc123...";
```

The corresponding `sha256` in the `pullImage` block must also be updated:

```nix
glancesImage = pkgs.dockerTools.pullImage {
  imageName = glancesImageReference.name;
  imageDigest = glancesImageReference.digest;
  finalImageTag = glancesImageReference.tag;
  sha256 = "sha256-xyz789...";  # This workflow updates this line
};
```

### Manual Usage

You can also run the hash update script manually:

```bash
.github/scripts/update-docker-hashes.sh
```

The script will:
- Exit with code 0 if changes were made
- Exit with code 1 if no changes were needed
- Exit with code >1 if an error occurred

### Troubleshooting

If the workflow fails:

1. Check the workflow logs for specific error messages
2. Verify that all Docker image references follow the expected format: `image:tag@sha256:digest`
3. Ensure the image exists in the registry and is accessible
4. Manually run `nix-prefetch-docker` to test fetching hashes for problematic images:

```bash
nix run nixpkgs#nix-prefetch-docker -- \
  --image-name "nicolargo/glances" \
  --image-digest "sha256:abc123..." \
  --final-image-tag "4.3.3"
```
