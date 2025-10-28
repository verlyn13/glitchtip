#!/usr/bin/env bash
# Export GlitchTip secrets from Infisical to .env format
# This script authenticates using Universal Auth via gopass-stored credentials

set -euo pipefail

# Configuration
PROJECT_ID="<TO_BE_CREATED>"  # Will be populated after machine identity creation
ENV="${INFISICAL_ENV:-prod}"
OUTPUT="${OUTPUT:-/dev/stdout}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[export-secrets]${NC} $*"; }
err() { echo -e "${RED}[export-secrets][ERROR]${NC} $*" >&2; exit 1; }
warn() { echo -e "${YELLOW}[export-secrets][WARN]${NC} $*" >&2; }

# Check prerequisites
command -v infisical >/dev/null 2>&1 || err "infisical CLI not found. Install: brew install infisical/get-cli/infisical"
command -v gopass >/dev/null 2>&1 || err "gopass not found. Install: brew install gopass"

# Retrieve credentials from gopass
log "Retrieving Universal Auth credentials from gopass..."
CLIENT_ID=$(gopass show infisical/machine-identities/hetzner-glitchtip-prod/client-id 2>/dev/null) || \
  err "Failed to retrieve client-id from gopass. Path: infisical/machine-identities/hetzner-glitchtip-prod/client-id"

CLIENT_SECRET=$(gopass show infisical/machine-identities/hetzner-glitchtip-prod/client-secret 2>/dev/null) || \
  err "Failed to retrieve client-secret from gopass. Path: infisical/machine-identities/hetzner-glitchtip-prod/client-secret"

[[ -z "${CLIENT_ID}" ]] && err "Client ID is empty"
[[ -z "${CLIENT_SECRET}" ]] && err "Client Secret is empty"

log "Authenticating with Infisical (Universal Auth)..."
export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID="${CLIENT_ID}"
export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET="${CLIENT_SECRET}"

# Export secrets from all paths
log "Exporting secrets from /glitchtip/database and /glitchtip/application..."

# Create temporary files for each path
TEMP_DB=$(mktemp)
TEMP_APP=$(mktemp)
trap 'rm -f "${TEMP_DB}" "${TEMP_APP}"' EXIT

# Export database secrets
infisical export \
  --projectId="${PROJECT_ID}" \
  --env="${ENV}" \
  --path=/glitchtip/database \
  --format=dotenv > "${TEMP_DB}" || err "Failed to export database secrets"

# Export application secrets
infisical export \
  --projectId="${PROJECT_ID}" \
  --env="${ENV}" \
  --path=/glitchtip/application \
  --format=dotenv > "${TEMP_APP}" || err "Failed to export application secrets"

# Combine secrets
{
  echo "# GlitchTip Secrets - Exported from Infisical"
  echo "# Project: glitchtip"
  echo "# Environment: ${ENV}"
  echo "# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  echo ""
  echo "# Database Configuration (/glitchtip/database)"
  cat "${TEMP_DB}"
  echo ""
  echo "# Application Configuration (/glitchtip/application)"
  cat "${TEMP_APP}"
} > "${OUTPUT}"

if [[ "${OUTPUT}" == "/dev/stdout" ]]; then
  log "✅ Secrets exported successfully to stdout"
else
  log "✅ Secrets exported successfully to: ${OUTPUT}"
  log "File permissions: $(stat -f '%Sp' "${OUTPUT}" 2>/dev/null || stat -c '%A' "${OUTPUT}" 2>/dev/null)"
fi

log "Total secrets exported: $(grep -c '^[A-Z_]*=' "${OUTPUT}" 2>/dev/null || echo "unknown")"
