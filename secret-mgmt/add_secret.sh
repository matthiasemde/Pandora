#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -n <secret-name> (-s <service> | -h <hostname>)"
  echo
  echo "  -n <secret-name>   Name of the secret (e.g. DB_PASSWORD)"
  echo "  -s <service>       Target service name (stores in ./services/<service>/secrets/)"
  echo "  -h <hostname>      Target hostname (stores in ./hosts/<hostname>/secrets/)"
  exit 1
}

SERVICE=""
HOST=""
SECRET_NAME=""

while getopts "s:h:n:" opt; do
  case "$opt" in
  s) SERVICE="$OPTARG" ;;
  h) HOST="$OPTARG" ;;
  n) SECRET_NAME="$OPTARG" ;;
  *) usage ;;
  esac
done

# Validation
if [[ "$(git rev-parse --show-toplevel)" != "$(pwd)" ]]; then
  echo "❌ Please run this script from the root of the Git repository."
  exit 1
fi

if [[ -z "$SECRET_NAME" || (-z "$SERVICE" && -z "$HOST") || (-n "$SERVICE" && -n "$HOST") ]]; then
  echo "❌ You must provide -n and either -s or -h (but not both)."
  usage
fi

# Determine secret paths
if [[ -n "$SERVICE" ]]; then
  SECRET_DIR="./services/${SERVICE}/secrets"
elif [[ -n "$HOST" ]]; then
  SECRET_DIR="./hosts/${HOST}/secrets"
fi

SECRET_PATH="${SECRET_DIR}/${SECRET_NAME}.age"
SECRET_META="${SECRET_PATH}.nix"

mkdir -p "$SECRET_DIR"

# Discover recipients
RECIPIENT_FILES=(./secrets/*)

RECIPIENT_KEYS=()
for file in "${RECIPIENT_FILES[@]}"; do
if [[ -f "$file" ]]; then
    key_line=$(sed -n 's/^# *Recipient: //p' "$file")
    if [[ -z "$key_line" ]]; then
      key_line=$(sed -n 's/^# public key: //p' "$file")
    fi
    if [[ -n "$key_line" ]]; then
      RECIPIENT_KEYS+=("\"$key_line\"")
    else
      echo "⚠️ Error: no recipient key found in $file"
      exit 0
    fi
  fi
done

if [[ ${#RECIPIENT_KEYS[@]} -eq 0 ]]; then
  echo "❌ No valid recipient keys found in ./secrets/"
  exit 1
fi

# Write .nix metadata
echo "{ \"${SECRET_PATH}\".publicKeys = [ ${RECIPIENT_KEYS[*]} ]; }" >"$SECRET_META"
echo "✅ Created: $SECRET_META"

export RULES=$SECRET_META

# Edit secret
echo "🔐 Opening secret: $SECRET_PATH"
EDITOR=vim agenix -e "$SECRET_PATH"
