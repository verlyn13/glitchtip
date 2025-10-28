# Secrets Management

## Overview
All secrets are managed in **Infisical** (see `../infisical` repo for setup).

**Project:** `glitchtip`
**Environment:** `prod`
**Authentication:** Universal Auth via machine identity `glitchtip-machine-identity`

## Secret Organization

Secrets are organized in Infisical using two paths:

1. **`/glitchtip/database`** - Database credentials ✅ Created
2. **`/glitchtip/application`** - Application configuration including email ✅ Created

**Folder IDs:**
- `/glitchtip/database`: `f729d1f6-e94f-4de0-b4f8-d0a47155fa1f`
- `/glitchtip/application`: `b9f54b93-2a85-4581-b5a9-6ca6c29823d8`

## Required Secrets

### Database Secrets (`/glitchtip/database`)

#### POSTGRES_PASSWORD
PostgreSQL database password for `glitchtip_maintainer` user.

**Generate:**
```bash
openssl rand -base64 32
```

**Storage:** Infisical → `/glitchtip/database/POSTGRES_PASSWORD`

### Application Secrets (`/glitchtip/application`)

#### SECRET_KEY
Django application secret key.

**Generate:**
```bash
openssl rand -hex 32
```

**Storage:** Infisical → `/glitchtip/application/SECRET_KEY`

#### EMAIL_URL
Postal SMTP connection string.

**Format:**
```
smtp://USERNAME:PASSWORD@smtp.postal.example.com:2525
```

**For Postal:**
```
smtp://glitchtip%40app:YOUR_PASSWORD@smtp.postal.jefahnierocks.com:2525
```

**Important:**
- URL-encode special characters: `@` → `%40`
- Port 2525 is Postal's default (plain SMTP, no TLS)
- Username/password from Postal SMTP credential

**Storage:** Infisical → `/glitchtip/application/EMAIL_URL`

**See:** [06-postal.md](./06-postal.md) for complete Postal setup

#### DEFAULT_FROM_EMAIL
From address for outbound emails.

**Format:**
```
glitchtip@jefahnierocks.com
```

**Requirements:**
- Must be verified domain in Postal
- SPF/DKIM configured

**Storage:** Infisical → `/glitchtip/application/DEFAULT_FROM_EMAIL`

## Secret Sync Process

### Authentication Method

Secrets are synced using **Universal Auth** with machine identity:
- **Machine Identity:** `glitchtip-machine-identity`
- **Credentials stored in:** gopass
- **Paths:**
  - `infisical/machine-identities/hetzner-glitchtip-prod/client-id`
  - `infisical/machine-identities/hetzner-glitchtip-prod/client-secret`

### Export Secrets Script

Use `export-secrets.sh` (preferred method):

```bash
cd /opt/docker/glitchtip
OUTPUT=.env ./scripts/export-secrets.sh
```

This script:
1. Retrieves Universal Auth credentials from gopass
2. Authenticates with Infisical using machine identity
3. Exports secrets from `/glitchtip/database` and `/glitchtip/application`
4. Combines them into `.env` file
5. Sets appropriate file permissions (600)

**Prerequisites:**
- `infisical` CLI installed
- `gopass` installed and configured
- Machine identity credentials stored in gopass

### Legacy Method (sync-secrets.sh)

The `sync-secrets.sh` script is deprecated in favor of `export-secrets.sh`.
It uses service token authentication instead of Universal Auth.

### Automated Sync (optional)

Add systemd service or cron job for periodic sync:

**Cron:**
```cron
0 */6 * * * cd /opt/docker/glitchtip && OUTPUT=.env ./scripts/export-secrets.sh
```

**Systemd Timer:** See `../hetzner` repo for systemd unit configuration

## Secret Rotation

### Rotating Application Secrets
1. Update secret in Infisical (path: `/glitchtip/application` or `/glitchtip/database`)
2. Export secrets:
   ```bash
   OUTPUT=.env ./scripts/export-secrets.sh
   ```
3. Restart affected services:
   ```bash
   docker compose restart
   ```

### Rotating POSTGRES_PASSWORD
1. Update password in Infisical (`/glitchtip/database/POSTGRES_PASSWORD`)
2. Update PostgreSQL user password:
   ```bash
   docker compose exec postgres psql -U glitchtip_maintainer -c \
     "ALTER USER glitchtip_maintainer PASSWORD 'new-password';"
   ```
3. Export secrets and restart:
   ```bash
   OUTPUT=.env ./scripts/export-secrets.sh
   docker compose restart
   ```

### Rotating Postal SMTP Credentials
1. Generate new SMTP credential in Postal web UI
2. Update `EMAIL_URL` in Infisical (`/glitchtip/application/EMAIL_URL`)
   - Remember to URL-encode: `@` → `%40`
3. Export secrets and restart:
   ```bash
   OUTPUT=.env ./scripts/export-secrets.sh
   docker compose restart web worker beat
   ```

## Security Notes
- `.env` file is gitignored (never commit)
- `.env.template` is tracked (no secrets, only documentation)
- Machine identity credentials stored in gopass (encrypted)
- File permissions: `.env` should be `600` (owner read/write only)
- Universal Auth credentials never exposed in logs or environment
- Secrets organized by purpose (database vs application)

## See Also
- [02-deployment.md](./02-deployment.md) - Deployment process
- [06-postal.md](./06-postal.md) - Postal SMTP integration
- `../infisical` - Infisical project setup and machine identity configuration
- [scripts/export-secrets.sh](../scripts/export-secrets.sh) - Secret export automation
- [.env.template](../.env.template) - Environment variable documentation
