# Secrets Management

## Overview
All secrets are managed in **Infisical** (see `../infisical` repo for setup).

Project: `glitchtip`
Environment: `prod`

## Required Secrets

### SECRET_KEY
Django application secret key.

**Generate:**
```bash
openssl rand -hex 32
```

**Storage:** Infisical → `glitchtip/prod/SECRET_KEY`

### POSTGRES_PASSWORD
PostgreSQL database password for `glitchtip_maintainer` user.

**Generate:**
```bash
openssl rand -base64 32
```

**Storage:** Infisical → `glitchtip/prod/POSTGRES_PASSWORD`

### EMAIL_URL
SMTP connection string for outbound email.

**Format:**
```
smtp://username:password@smtp.provider.com:587
```

**Examples:**
- SendGrid: `smtp://apikey:SG.xxx@smtp.sendgrid.net:587`
- Gmail: `smtp://user@gmail.com:app-password@smtp.gmail.com:587`
- Mailgun: `smtp://postmaster@domain:password@smtp.mailgun.org:587`

**Storage:** Infisical → `glitchtip/prod/EMAIL_URL`

## Secret Sync Process

### Manual Sync
```bash
cd /opt/glitchtip
./scripts/sync-secrets.sh
```

This script:
1. Connects to Infisical using service token
2. Fetches secrets from `glitchtip/prod`
3. Generates `.env` from `.env.template`
4. Sets appropriate file permissions (600)

### Automated Sync (optional)
Add cron job for periodic sync:
```cron
0 */6 * * * cd /opt/glitchtip && ./scripts/sync-secrets.sh
```

## Secret Rotation

### Rotating Secrets
1. Update secret in Infisical
2. Run `./scripts/sync-secrets.sh`
3. Restart affected services:
   ```bash
   docker compose restart
   ```

### Rotating DATABASE_URL / POSTGRES_PASSWORD
1. Update password in Infisical
2. Update PostgreSQL user password:
   ```bash
   docker compose exec postgres psql -U glitchtip_maintainer -c \
     "ALTER USER glitchtip_maintainer PASSWORD 'new-password';"
   ```
3. Sync secrets and restart:
   ```bash
   ./scripts/sync-secrets.sh
   docker compose restart
   ```

## Security Notes
- `.env` file is gitignored (never commit)
- `.env.template` is tracked (no secrets)
- Service token stored in host environment or systemd service
- File permissions: `.env` should be `600` (owner read/write only)

## See Also
- [02-deployment.md](./02-deployment.md) - Deployment process
- `../infisical` - Infisical project setup
- [scripts/sync-secrets.sh](../scripts/sync-secrets.sh) - Sync automation
