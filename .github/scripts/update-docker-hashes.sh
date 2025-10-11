#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if any changes were made
CHANGES_MADE=false

echo "Starting Docker image hash update process..."

# Find all service flake.nix files
for flake in services/*/flake.nix; do
  if [ ! -f "$flake" ]; then
    continue
  fi
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Processing: $flake"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Create a temporary file for storing the updated content
  temp_file=$(mktemp)
  cp "$flake" "$temp_file"
  
  # Extract all Docker image references from the file
  # Pattern: variableRawImageReference = "image:tag@sha256:digest"
  while IFS= read -r line; do
    # Extract the variable name
    var_name=$(echo "$line" | sed -E 's/^[[:space:]]*([a-zA-Z0-9_]+)RawImageReference.*/\1/')
    
    # Extract the full image reference
    image_ref=$(echo "$line" | sed -E 's/.*"([^"]+)".*/\1/')
    
    # Parse image components
    # Format: registry/image:tag@sha256:digest
    image_with_tag=$(echo "$image_ref" | sed -E 's/@sha256:.+$//')
    image_name=$(echo "$image_with_tag" | sed -E 's/:([^:]+)$//')
    image_tag=$(echo "$image_with_tag" | sed -E 's/.*:([^:]+)$/\1/')
    image_digest=$(echo "$image_ref" | sed -E 's/.*@(sha256:[a-f0-9]+).*/\1/')
    
    echo ""
    echo -e "${YELLOW}Image:${NC} $image_name"
    echo -e "${YELLOW}Tag:${NC} $image_tag"
    echo -e "${YELLOW}Digest:${NC} $image_digest"
    
    # Use nix-prefetch-docker to get the correct SHA256 hash
    echo -e "${YELLOW}Fetching Nix hash...${NC}"
    
    # Run nix-prefetch-docker and capture output
    if ! nix_output=$(nix run nixpkgs#nix-prefetch-docker -- \
      --image-name "$image_name" \
      --image-digest "$image_digest" \
      --final-image-tag "$image_tag" 2>&1); then
      echo -e "${RED}Error: Failed to fetch hash for $image_name:$image_tag@$image_digest${NC}"
      echo "$nix_output"
      continue
    fi
    
    # Extract the sha256 hash from the output
    # nix-prefetch-docker outputs the hash in the format: sha256-...
    nix_hash=$(echo "$nix_output" | grep -oP 'sha256-[A-Za-z0-9+/=]+' | head -1)
    
    if [ -z "$nix_hash" ]; then
      echo -e "${RED}Warning: Could not extract hash from nix-prefetch-docker output${NC}"
      echo "$nix_output"
      continue
    fi
    
    echo -e "${GREEN}Nix hash:${NC} $nix_hash"
    
    # Find the current hash for this image
    current_hash=$(awk -v var="$var_name" '
      BEGIN { in_section = 0 }
      $0 ~ var "RawImageReference" { in_section = 1; next }
      in_section && /sha256 = "sha256-/ {
        match($0, /sha256 = "([^"]+)"/, arr)
        print arr[1]
        exit
      }
      in_section && /^[[:space:]]*[a-zA-Z0-9_]+RawImageReference/ { exit }
    ' "$temp_file")
    
    if [ -z "$current_hash" ]; then
      echo -e "${RED}Warning: Could not find current hash for $var_name in $flake${NC}"
      continue
    fi
    
    echo -e "${YELLOW}Current hash:${NC} $current_hash"
    
    # Update the hash if it's different
    if [ "$current_hash" != "$nix_hash" ]; then
      echo -e "${GREEN}✓ Updating hash${NC}"
      
      # Use awk to find and replace the sha256 line within the correct image block
      awk -v var="$var_name" -v new_hash="$nix_hash" '
        BEGIN { in_section = 0 }
        $0 ~ var "RawImageReference" {
          in_section = 1
          print
          next
        }
        in_section && /sha256 = "sha256-/ {
          sub(/sha256 = "sha256-[^"]+";/, "sha256 = \"" new_hash "\";")
          in_section = 0
          print
          next
        }
        in_section && /^[[:space:]]*[a-zA-Z0-9_]+RawImageReference/ {
          in_section = 0
        }
        { print }
      ' "$temp_file" > "${temp_file}.new" && mv "${temp_file}.new" "$temp_file"
      
      CHANGES_MADE=true
    else
      echo -e "${GREEN}✓ Hash is already up to date${NC}"
    fi
    
  done < <(grep -E '^[[:space:]]*[a-zA-Z0-9_]+RawImageReference[[:space:]]*=[[:space:]]*"[^"]+@sha256:[^"]+"' "$flake")
  
  # If changes were made to this file, update it
  if ! cmp -s "$flake" "$temp_file"; then
    mv "$temp_file" "$flake"
    echo -e "${GREEN}✓ Updated $flake${NC}"
  else
    rm "$temp_file"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$CHANGES_MADE" = true ]; then
  echo -e "${GREEN}✓ Hash updates complete - changes were made${NC}"
  exit 0
else
  echo -e "${YELLOW}✓ Hash updates complete - no changes needed${NC}"
  exit 1
fi
