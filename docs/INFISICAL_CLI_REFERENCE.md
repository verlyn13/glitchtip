# Infisical CLI Quick Reference

Essential commands for GlitchTip secret management.

## Authentication

### Universal Auth (Machine Identity)
```bash
# Export token for subsequent commands
export INFISICAL_TOKEN=$(infisical login \
  --method=universal-auth \
  --client-id=<identity-client-id> \
  --client-secret=<identity-client-secret> \
  --silent --plain)

# Disable update checks (recommended for scripts/CI)
export INFISICAL_DISABLE_UPDATE_CHECK=true
```

**For GlitchTip:** Credentials stored in gopass:
- `infisical/machine-identities/hetzner-glitchtip-prod/client-id`
- `infisical/machine-identities/hetzner-glitchtip-prod/client-secret`

## Core Commands

### List Secrets
```bash
# List all secrets in environment
infisical secrets --projectId=<project-id> --env=prod --path=/

# List secrets in specific folder
infisical secrets --projectId=<project-id> --env=prod --path=/glitchtip/database

# Plain output (no formatting)
infisical secrets --projectId=<project-id> --env=prod --path=/ --plain --silent
```

### Get Specific Secret
```bash
# Get single secret
infisical secrets get SECRET_KEY --projectId=<project-id> --env=prod --path=/glitchtip/application

# Get multiple secrets
infisical secrets get SECRET_KEY EMAIL_URL --projectId=<project-id> --env=prod --path=/glitchtip/application

# Get secret value only (for scripts)
SECRET=$(infisical secrets get SECRET_KEY --projectId=<project-id> --env=prod --path=/glitchtip/application --plain --silent)
```

### Set/Update Secrets
```bash
# Set single secret
infisical secrets set SECRET_KEY=value123 --projectId=<project-id> --env=prod --path=/glitchtip/application

# Set multiple secrets
infisical secrets set \
  SECRET_KEY=value123 \
  EMAIL_URL=smtp://user:pass@host:port \
  --projectId=<project-id> --env=prod --path=/glitchtip/application

# Load secret from file
infisical secrets set CERT_PEM=@/path/to/cert.pem --projectId=<project-id> --env=prod --path=/

# Set secrets from .env file
infisical secrets set --file=.env --projectId=<project-id> --env=prod --path=/glitchtip/application
```

**Special characters:**
- Use `secretName=@path/to/file` to load from file
- Use `secretName=\@value` for literal `@` at start

### Delete Secrets
```bash
# Delete single secret
infisical secrets delete OLD_SECRET --projectId=<project-id> --env=prod --path=/glitchtip/application

# Delete multiple secrets
infisical secrets delete OLD_SECRET1 OLD_SECRET2 --projectId=<project-id> --env=prod --path=/glitchtip/application
```

### Folder Management

#### List Folders
```bash
# List folders at root
infisical secrets folders get --projectId=<project-id> --env=prod --path=/

# List folders in path
infisical secrets folders get --projectId=<project-id> --env=prod --path=/glitchtip
```

#### Create Folder
```bash
# Create folder
infisical secrets folders create \
  --name=database \
  --path=/glitchtip \
  --projectId=<project-id> \
  --env=prod
```

#### Delete Folder
```bash
# Delete folder (will delete all secrets inside!)
infisical secrets folders delete \
  --name=database \
  --path=/glitchtip \
  --projectId=<project-id> \
  --env=prod
```

### Run Commands with Secrets Injected
```bash
# Run single command
infisical run --projectId=<project-id> --env=prod --path=/glitchtip/application -- npm run dev

# Run chained commands
infisical run --projectId=<project-id> --env=prod --command="npm run build && npm run start"

# Watch for secret changes and auto-restart
infisical run --watch --projectId=<project-id> --env=prod -- npm run dev

# Include secrets from specific folder
infisical run --projectId=<project-id> --env=prod --path=/glitchtip/application -- printenv
```

### Export Secrets
```bash
# Export to .env format (stdout)
infisical export --projectId=<project-id> --env=prod --path=/glitchtip/database --format=dotenv

# Export to file
infisical export --projectId=<project-id> --env=prod --path=/glitchtip/database --format=dotenv > .env

# Export multiple paths (manual merge)
infisical export --projectId=<project-id> --env=prod --path=/glitchtip/database --format=dotenv > .env.tmp
infisical export --projectId=<project-id> --env=prod --path=/glitchtip/application --format=dotenv >> .env.tmp
mv .env.tmp .env
```

## Common Flags

| Flag                | Description                                      | Default   |
|---------------------|--------------------------------------------------|-----------|
| `--projectId`       | Project ID (required for machine identity)       | -         |
| `--env`             | Environment slug (dev, staging, prod)            | `dev`     |
| `--path`            | Folder path to operate on                        | `/`       |
| `--plain`           | Output raw values without formatting             | `false`   |
| `--silent`          | Disable info/tip messages (for scripts)          | `false`   |
| `--expand`          | Parse shell parameter expansions                 | `true`    |
| `--include-imports` | Include imported secrets                         | `true`    |
| `--tags`            | Filter by tag slugs (comma-separated)            | -         |

## GlitchTip-Specific Workflow

### Initial Setup
```bash
# 1. Get project ID from .infisical.json
PROJECT_ID=$(cat .infisical.json | grep workspaceId | cut -d'"' -f4)

# 2. Export auth token from gopass
export INFISICAL_TOKEN=$(infisical login \
  --method=universal-auth \
  --client-id=$(gopass show infisical/machine-identities/hetzner-glitchtip-prod/client-id) \
  --client-secret=$(gopass show infisical/machine-identities/hetzner-glitchtip-prod/client-secret) \
  --silent --plain)

# 3. Create folder structure
infisical secrets folders create --name=glitchtip --path=/ --projectId=$PROJECT_ID --env=prod
infisical secrets folders create --name=database --path=/glitchtip --projectId=$PROJECT_ID --env=prod
infisical secrets folders create --name=application --path=/glitchtip --projectId=$PROJECT_ID --env=prod

# 4. Set database secrets
infisical secrets set \
  POSTGRES_PASSWORD=$(openssl rand -base64 32) \
  --projectId=$PROJECT_ID --env=prod --path=/glitchtip/database

# 5. Set application secrets
infisical secrets set \
  SECRET_KEY=$(openssl rand -hex 32) \
  EMAIL_URL='smtp://glitchtip%40app:PASSWORD@smtp.postal.jefahnierocks.com:2525' \
  DEFAULT_FROM_EMAIL='glitchtip@jefahnierocks.com' \
  --projectId=$PROJECT_ID --env=prod --path=/glitchtip/application
```

### Daily Operations
```bash
# List all secrets
infisical secrets --projectId=$PROJECT_ID --env=prod --path=/glitchtip/database
infisical secrets --projectId=$PROJECT_ID --env=prod --path=/glitchtip/application

# Update a secret
infisical secrets set EMAIL_URL='new-value' --projectId=$PROJECT_ID --env=prod --path=/glitchtip/application

# Export secrets for deployment (see scripts/export-secrets.sh)
OUTPUT=.env ./scripts/export-secrets.sh
```

## Best Practices

1. **Always use `--silent --plain` in scripts** to avoid update messages and formatting
2. **Use `INFISICAL_DISABLE_UPDATE_CHECK=true`** in CI/CD and production
3. **Store machine identity credentials in gopass** or secure vault
4. **Use `--path` to organize secrets** by component (database, application, etc.)
5. **Never commit `INFISICAL_TOKEN`** to version control
6. **Use `--watch` flag** during development to auto-reload on secret changes
7. **Test secret changes** in dev environment before applying to prod

## Security Notes

- Machine identity tokens expire and must be refreshed
- Use `--silent` flag to prevent token leakage in logs
- Store credentials in gopass with proper GPG encryption
- Audit secret access via Infisical web UI
- Rotate machine identity credentials periodically

## See Also
- [03-secrets.md](./03-secrets.md) - GlitchTip secret management
- [scripts/export-secrets.sh](../scripts/export-secrets.sh) - Automated export script
- Infisical Docs: https://infisical.com/docs/cli/overview
