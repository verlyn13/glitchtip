# Postal SMTP Integration

## Overview

GlitchTip is configured to use **Postal** as its SMTP backend for sending transactional emails. Postal will be configured in the `../hetzner` infrastructure repository.

**Purpose:** Password resets, user invitations, alert notifications, error reports

## Required Configuration

### Infisical Secrets

The following secrets must be set in Infisical (`/glitchtip/application` path):

#### EMAIL_URL
Full SMTP connection string for Postal.

**Format:**
```
smtp://USERNAME:PASSWORD@smtp.postal.example.com:2525
```

**For your setup:**
```
smtp://glitchtip%40app:YOUR_PASSWORD@smtp.postal.jefahnierocks.com:2525
```

**Important Notes:**
- URL-encode special characters: `@` becomes `%40`
- Default Postal SMTP port: `2525` (plain SMTP, no TLS)
- Username format: typically `servicename@app` or as configured in Postal

**Generate in Postal:**
1. Log into Postal web UI
2. Navigate to your mail server
3. Create SMTP credential: "glitchtip"
4. Copy username and password
5. Format as URL (remember to encode `@` symbol)

#### DEFAULT_FROM_EMAIL
Email address for outbound messages.

**Format:**
```
glitchtip@jefahnierocks.com
```

**Requirements:**
- Must be a verified sending domain in Postal
- Should have SPF/DKIM configured
- Recommendation: Use subdomain or dedicated address

## Environment Variables

These are configured in [docker-compose.yml](../docker-compose.yml):

| Variable                  | Value                                        | Purpose                          |
|---------------------------|----------------------------------------------|----------------------------------|
| `EMAIL_URL`               | (from Infisical)                             | SMTP connection string           |
| `EMAIL_BACKEND`           | `django.core.mail.backends.smtp.EmailBackend` | Use SMTP for email              |
| `DEFAULT_FROM_EMAIL`      | (from Infisical)                             | From address for emails          |
| `EMAIL_USE_TLS`           | `"False"`                                    | Postal uses plain SMTP           |
| `EMAIL_USE_SSL`           | `"False"`                                    | Not needed for port 2525         |
| `EMAIL_TIMEOUT`           | `"10"`                                       | Prevents hanging connections     |
| `EMAIL_SUBJECT_PREFIX`    | `"[GlitchTip]"`                              | Subject line prefix              |

## Postal Prerequisites

Before GlitchTip can send email, Postal must be configured (in `../hetzner` repo):

### Postal Setup Checklist

| Requirement                  | Status | Notes                                    |
|------------------------------|--------|------------------------------------------|
| Postal server deployed       | ⏳     | See `../hetzner` deployment              |
| Mail server created          | ⏳     | Create in Postal web UI                  |
| SMTP credential created      | ⏳     | Username: `glitchtip@app`                |
| Sending domain verified      | ⏳     | Domain: `jefahnierocks.com`              |
| SPF record configured        | ⏳     | DNS: `v=spf1 ...`                        |
| DKIM keys installed          | ⏳     | Add TXT records to DNS                   |
| Return path domain set       | ⏳     | Typically `rp.jefahnierocks.com`         |
| Port 2525 accessible         | ⏳     | Internal network or firewall configured  |

## Testing Email Configuration

### 1. Basic Connection Test

From GlitchTip container:
```bash
docker compose exec web python manage.py shell

# In Python shell:
from django.core.mail import send_mail
send_mail(
    'Test from GlitchTip',
    'This is a test email.',
    'glitchtip@jefahnierocks.com',
    ['your-email@example.com'],
    fail_silently=False,
)
```

### 2. GlitchTip Test Email

Via Django admin:
```bash
docker compose exec web python manage.py sendtestemail your-email@example.com
```

### 3. Check Logs

GlitchTip logs:
```bash
docker compose logs web | grep -i email
docker compose logs web | grep -i smtp
```

Postal logs:
```bash
# See ../hetzner repo for Postal log access
```

## Troubleshooting

### Connection Refused
```
SMTPServerDisconnected: Connection unexpectedly closed
```

**Causes:**
- Postal not running
- Wrong SMTP host/port
- Network routing issue

**Solutions:**
- Verify Postal is running: check `../hetzner` deployment
- Verify network connectivity: `docker compose exec web nc -zv smtp.postal.jefahnierocks.com 2525`
- Check Docker network configuration

### Authentication Failed
```
SMTPAuthenticationError: (535, b'5.7.8 Authentication failed')
```

**Causes:**
- Wrong username/password
- Special characters not URL-encoded
- SMTP credential not created in Postal

**Solutions:**
- Verify credentials in Postal web UI
- Check EMAIL_URL encoding: `@` must be `%40`
- Regenerate SMTP credential in Postal

### Email Not Delivered
```
Email sent successfully but not received
```

**Causes:**
- SPF/DKIM not configured
- Domain not verified in Postal
- Recipient's spam filter

**Solutions:**
- Verify SPF/DKIM in Postal and DNS (see `../hetzner` repo)
- Check Postal queue: Postal web UI → Message Queue
- Check recipient spam folder
- Verify sending domain status in Postal

### Timeout Errors
```
SMTPServerDisconnected: timed out
```

**Causes:**
- Network latency
- Postal overloaded
- Firewall blocking connection

**Solutions:**
- Increase `EMAIL_TIMEOUT` in docker-compose.yml
- Check Postal server resources
- Verify firewall rules

## Security Notes

### Credential Storage
- SMTP credentials stored in Infisical
- Retrieved via machine identity (Universal Auth)
- Never committed to git
- See [03-secrets.md](./03-secrets.md) for secret management

### Network Security
- GlitchTip → Postal communication should be on private network
- If Postal is external, use TLS (change `EMAIL_USE_TLS` to `"True"`)
- Consider VPN or SSH tunnel for production

### Email Content
- GlitchTip may send error details via email
- Ensure error messages don't expose sensitive data
- Configure `GLITCHTIP_MAX_EVENT_LIFE_DAYS` to limit data retention

## Integration Testing

### Full Flow Test
1. Create test user in GlitchTip
2. Send password reset email
3. Verify email received
4. Check Postal logs for successful delivery
5. Verify email formatting and links work

### Monitoring
- Monitor email queue in Postal
- Set up alerts for failed deliveries
- Track bounce rates
- Monitor SMTP connection errors in GlitchTip logs

## See Also
- [03-secrets.md](./03-secrets.md) - Secret management with Infisical
- [02-deployment.md](./02-deployment.md) - Deployment process
- `../hetzner` - Postal server deployment
- [docker-compose.yml](../docker-compose.yml) - Email environment variables
- [.env.template](../.env.template) - Environment variable template

## Postal Documentation
- Postal GitHub: https://github.com/postalserver/postal
- Postal Docs: https://docs.postalserver.io/
- SMTP Configuration: https://docs.postalserver.io/getting-started/smtp
