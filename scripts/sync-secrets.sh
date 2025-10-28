#!/usr/bin/env bash
# Sync secrets from Infisical to .env file
# See: docs/03-secrets.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
ENV_TEMPLATE="$REPO_ROOT/.env.template"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Infisical CLI is installed
if ! command -v infisical &> /dev/null; then
    log_error "Infisical CLI not found. Please install it first."
    log_info "Install: https://infisical.com/docs/cli/overview"
    exit 1
fi

# Check if template exists
if [[ ! -f "$ENV_TEMPLATE" ]]; then
    log_error ".env.template not found at $ENV_TEMPLATE"
    exit 1
fi

log_info "Syncing secrets from Infisical (project: glitchtip, env: prod)..."

# Fetch secrets and generate .env
cd "$REPO_ROOT"

# Option 1: Use infisical export (creates .env directly)
if infisical export --env=prod --format=dotenv > "$ENV_FILE.tmp" 2>/dev/null; then
    mv "$ENV_FILE.tmp" "$ENV_FILE"
    log_info "Secrets synced successfully to $ENV_FILE"
else
    log_error "Failed to sync secrets from Infisical"
    log_warn "Ensure you're authenticated: infisical login"
    log_warn "Or set INFISICAL_TOKEN environment variable"
    exit 1
fi

# Set secure permissions
chmod 600 "$ENV_FILE"
log_info "Set file permissions to 600 (owner read/write only)"

# Validate required secrets
REQUIRED_SECRETS=("SECRET_KEY" "POSTGRES_PASSWORD" "EMAIL_URL")
MISSING_SECRETS=()

for secret in "${REQUIRED_SECRETS[@]}"; do
    if ! grep -q "^${secret}=" "$ENV_FILE"; then
        MISSING_SECRETS+=("$secret")
    fi
done

if [[ ${#MISSING_SECRETS[@]} -gt 0 ]]; then
    log_warn "Missing required secrets: ${MISSING_SECRETS[*]}"
    log_warn "Please add them in Infisical: https://app.infisical.com"
    exit 1
fi

log_info "All required secrets present"
log_info "Sync complete! Run 'docker compose up -d' to apply changes"
