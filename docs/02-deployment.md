# Deployment Guide

## Prerequisites

### Infrastructure (managed in `../hetzner`)
- Ubuntu 24.04 LTS server provisioned
- Docker and Docker Compose installed
- Traefik running on `traefik-public` network
- Cloudflare DNS configured: `glitchtip.jefahnierocks.com` → server IP

### Secrets (managed in `../infisical`)
- Infisical project: `glitchtip`
- Required secrets configured (see [03-secrets.md](./03-secrets.md))

## Deployment Steps

### 1. Clone Repository
```bash
cd /opt
git clone git@github.com:verlyn13/glitchtip.git
cd glitchtip
```

### 2. Sync Secrets from Infisical
```bash
./scripts/sync-secrets.sh
# Generates .env from Infisical secrets
```

### 3. Create External Network (if not exists)
```bash
docker network create traefik-public 2>/dev/null || true
```

### 4. Deploy Stack
```bash
docker compose up -d
```

### 5. Verify Services
```bash
docker compose ps
docker compose logs web
```

### 6. Initialize Superuser
```bash
docker compose exec web ./manage.py createsuperuser
# Follow prompts to create admin user
```

### 7. Access Application
- URL: https://glitchtip.jefahnierocks.com
- Admin: https://glitchtip.jefahnierocks.com/admin/

## Environment Variables

### Required (from Infisical)
- `SECRET_KEY`: Django secret (generate with `openssl rand -hex 32`)
- `POSTGRES_PASSWORD`: Database password
- `EMAIL_URL`: SMTP connection string

### Application Settings
Configured in [docker-compose.yml](../docker-compose.yml):
- `GLITCHTIP_DOMAIN`: https://glitchtip.jefahnierocks.com
- `DEFAULT_FROM_EMAIL`: info@jefahnierocks.com
- `I_PAID_FOR_GLITCHTIP`: true
- `ENABLE_USER_REGISTRATION`: false
- `ENABLE_ORGANIZATION_CREATION`: false
- `GLITCHTIP_MAX_EVENT_LIFE_DAYS`: 90

## Post-Deployment Configuration

### OAuth Providers (optional)
Visit `/admin/` to configure:
- GitHub
- GitLab
- Google
- Microsoft
- OpenID Connect

Callback URL format: `https://glitchtip.jefahnierocks.com/accounts/{provider}/login/callback/`

### Organization Setup
1. Create organization via web UI
2. Generate client DSN keys for each project
3. Configure SDK in your applications

## Upgrading

### Pull Latest Images
```bash
docker compose pull
```

### Restart Services
```bash
docker compose up -d
```

Migrations run automatically on container start.

## See Also
- [01-architecture.md](./01-architecture.md) - System overview
- [03-secrets.md](./03-secrets.md) - Secret management
- [05-maintenance.md](./05-maintenance.md) - Operations guide
