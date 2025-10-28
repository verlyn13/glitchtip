# GlitchTip Self-Hosted Configuration

Production-ready self-hosted GlitchTip error tracking deployment for `glitchtip.jefahnierocks.com`.

## Quick Start

```bash
# 1. Export secrets from Infisical (requires gopass)
OUTPUT=.env ./scripts/export-secrets.sh

# 2. Deploy stack
./scripts/deploy.sh

# 3. Create admin user
docker compose exec web ./manage.py createsuperuser

# 4. Access application
open https://glitchtip.jefahnierocks.com
```

## Documentation Index

### Core Documentation
- **[01-architecture.md](docs/01-architecture.md)** - System overview and component architecture
- **[02-deployment.md](docs/02-deployment.md)** - Complete deployment guide and configuration
- **[03-secrets.md](docs/03-secrets.md)** - Secret management with Infisical (Universal Auth)
- **[04-traefik.md](docs/04-traefik.md)** - Reverse proxy and TLS configuration
- **[05-maintenance.md](docs/05-maintenance.md)** - Operations, backups, and troubleshooting
- **[06-postal.md](docs/06-postal.md)** - Postal SMTP integration for email

### Configuration Files
- **[docker-compose.yml](docker-compose.yml)** - Service definitions
- **[.env.template](.env.template)** - Environment variable template
- **[config/traefik/labels.yml](config/traefik/labels.yml)** - Traefik label reference

### Automation Scripts
- **[scripts/deploy.sh](scripts/deploy.sh)** - Full deployment automation
- **[scripts/export-secrets.sh](scripts/export-secrets.sh)** - Infisical secret export (Universal Auth)
- **[scripts/sync-secrets.sh](scripts/sync-secrets.sh)** - Legacy secret sync (deprecated)
- **[scripts/backup.sh](scripts/backup.sh)** - Database backup automation

## Stack Components

- **GlitchTip**: Error tracking platform (latest)
- **PostgreSQL**: 15-alpine (primary database)
- **Redis**: 7-alpine (cache + Celery broker)
- **Traefik**: Reverse proxy with Cloudflare TLS

## Related Repositories

This is part of a multi-repo deployment system:

- **`../hetzner`** - Server provisioning, Traefik deployment, infrastructure
- **`../infisical`** - Secret management project configuration
- **`glitchtip`** (this repo) - GlitchTip application configuration

## System Requirements

- Ubuntu 24.04 LTS (x86_64)
- Docker + Docker Compose v2.27+
- 1GB RAM minimum (2GB recommended)
- 1 vCPU (2 vCPU recommended)
- ~30GB storage per million events

## Infrastructure

**Host:** Hetzner Cloud Ubuntu 24.04
**Deploy Path:** `/opt/docker/glitchtip/`
**Domain:** glitchtip.jefahnierocks.com
**Reverse Proxy:** Traefik on `proxy` network (managed in `../hetzner`)
**TLS:** Cloudflare origin certificates
**Email:** Postal SMTP (managed in `../hetzner`, see [docs/06-postal.md](docs/06-postal.md))
**Secrets:** Infisical (project: `glitchtip`, machine identity auth via gopass)

## Common Operations

### View Logs
```bash
docker compose logs -f web
docker compose logs worker
```

### Restart Services
```bash
docker compose restart
```

### Upgrade
```bash
docker compose pull
docker compose up -d
```

### Backup Database
```bash
./scripts/backup.sh
```

### Check Service Health
```bash
docker compose ps
docker compose exec web ./manage.py check
```

## Support

GlitchTip is open-source software. Consider supporting the project:
- **Recommended donation:** $5/user/month
- **Contact:** sales@glitchtip.com
- **License:** MIT

## Documentation Structure

All documentation uses cross-references to avoid duplication:
- Infrastructure details → `../hetzner` repo
- Secret configuration → `../infisical` repo
- Application deployment → this repo (see `docs/`)
