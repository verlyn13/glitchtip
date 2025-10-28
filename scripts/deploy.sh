#!/usr/bin/env bash
# GlitchTip deployment automation
# See: docs/02-deployment.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cd "$REPO_ROOT"

# Step 1: Sync secrets
log_info "Step 1/5: Syncing secrets from Infisical..."
if [[ -x "$SCRIPT_DIR/sync-secrets.sh" ]]; then
    "$SCRIPT_DIR/sync-secrets.sh"
else
    log_error "sync-secrets.sh not found or not executable"
    exit 1
fi

# Step 2: Create external network if needed
log_info "Step 2/5: Ensuring traefik-public network exists..."
if docker network create traefik-public 2>/dev/null; then
    log_info "Created traefik-public network"
else
    log_warn "traefik-public network already exists (OK)"
fi

# Step 3: Pull latest images
log_info "Step 3/5: Pulling latest Docker images..."
docker compose pull

# Step 4: Deploy stack
log_info "Step 4/5: Starting services..."
docker compose up -d

# Step 5: Wait for services to be healthy
log_info "Step 5/5: Waiting for services to be healthy..."
sleep 5

# Check service health
if docker compose ps | grep -q "unhealthy\|Exit"; then
    log_error "Some services are unhealthy:"
    docker compose ps
    log_info "Check logs with: docker compose logs"
    exit 1
fi

log_info "Deployment complete!"
log_info ""
log_info "Next steps:"
log_info "  1. Create superuser: docker compose exec web ./manage.py createsuperuser"
log_info "  2. Access application: https://glitchtip.jefahnierocks.com"
log_info "  3. View logs: docker compose logs -f"
