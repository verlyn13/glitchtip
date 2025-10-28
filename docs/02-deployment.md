# Deployment Guide

## Prerequisites

### Infrastructure (managed in `../hetzner`)
- Ubuntu 24.04 LTS server provisioned
- Docker and Docker Compose installed
- Traefik running on `proxy` network
- Cloudflare DNS configured: `glitchtip.jefahnierocks.com` → server IP
- (Optional) Postal deployed for email functionality

### Secrets (managed in `../infisical`)
- Infisical project: `glitchtip`
- Machine identity: `glitchtip-machine-identity` configured
- Required secrets configured (see [03-secrets.md](./03-secrets.md))
- Machine identity credentials stored in gopass

## Deployment Steps

### 1. Clone Repository
```bash
cd /opt/docker
git clone git@github.com:verlyn13/glitchtip.git
cd glitchtip
```

### 2. Export Secrets from Infisical
```bash
OUTPUT=.env ./scripts/export-secrets.sh
# Exports secrets from /glitchtip/database and /glitchtip/application
```

**Prerequisites:**
- `infisical` CLI installed
- `gopass` configured with machine identity credentials

### 3. Create External Network (if not exists)
```bash
docker network create proxy 2>/dev/null || true
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

### Required Secrets (from Infisical)

**Database secrets** (`/glitchtip/database`):
- `POSTGRES_PASSWORD`: Database password

**Application secrets** (`/glitchtip/application`):
- `SECRET_KEY`: Django secret (generate with `openssl rand -hex 32`)
- `EMAIL_URL`: Postal SMTP connection string (see [06-postal.md](./06-postal.md))
- `DEFAULT_FROM_EMAIL`: From address (must be verified in Postal)

### Application Settings
Configured in [docker-compose.yml](../docker-compose.yml):
- `GLITCHTIP_DOMAIN`: https://glitchtip.jefahnierocks.com
- `I_PAID_FOR_GLITCHTIP`: true
- `ENABLE_USER_REGISTRATION`: false
- `ENABLE_ORGANIZATION_CREATION`: false
- `GLITCHTIP_MAX_EVENT_LIFE_DAYS`: 90

### Email Configuration (Postal)
Configured in [docker-compose.yml](../docker-compose.yml):
- `EMAIL_BACKEND`: django.core.mail.backends.smtp.EmailBackend
- `EMAIL_USE_TLS`: False
- `EMAIL_USE_SSL`: False
- `EMAIL_TIMEOUT`: 10
- `EMAIL_SUBJECT_PREFIX`: [GlitchTip]

See [06-postal.md](./06-postal.md) for complete email setup

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
- [06-postal.md](./06-postal.md) - Postal email integration
- [05-maintenance.md](./05-maintenance.md) - Operations guide
- [04-traefik.md](./04-traefik.md) - Reverse proxy configuration
