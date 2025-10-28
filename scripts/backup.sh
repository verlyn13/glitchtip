#!/usr/bin/env bash
# GlitchTip database backup automation
# See: docs/05-maintenance.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$REPO_ROOT/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/glitchtip-backup-$TIMESTAMP.sql.gz"

# Retention (days)
RETENTION_DAYS=30

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

# Create backup directory
mkdir -p "$BACKUP_DIR"

cd "$REPO_ROOT"

# Check if services are running
if ! docker compose ps postgres | grep -q "Up"; then
    log_error "PostgreSQL service is not running"
    exit 1
fi

log_info "Starting database backup..."
log_info "Backup file: $BACKUP_FILE"

# Perform backup
if docker compose exec -T postgres pg_dump -U glitchtip_maintainer glitchtip | gzip > "$BACKUP_FILE"; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log_info "Backup completed successfully (Size: $BACKUP_SIZE)"
else
    log_error "Backup failed"
    rm -f "$BACKUP_FILE"
    exit 1
fi

# Clean up old backups
log_info "Cleaning up backups older than $RETENTION_DAYS days..."
OLD_BACKUPS=$(find "$BACKUP_DIR" -name "glitchtip-backup-*.sql.gz" -mtime +$RETENTION_DAYS)

if [[ -n "$OLD_BACKUPS" ]]; then
    echo "$OLD_BACKUPS" | while read -r old_backup; do
        log_info "Removing old backup: $(basename "$old_backup")"
        rm -f "$old_backup"
    done
else
    log_info "No old backups to remove"
fi

# List recent backups
log_info "Recent backups:"
ls -lh "$BACKUP_DIR"/glitchtip-backup-*.sql.gz 2>/dev/null | tail -5 || log_warn "No backups found"

log_info "Backup complete!"
