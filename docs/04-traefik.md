# Traefik Integration

## Overview
GlitchTip integrates with Traefik via Docker labels for automatic service discovery and routing.

**Traefik deployment:** Managed in `../hetzner` repo
**Domain:** glitchtip.jefahnierocks.com
**TLS:** Cloudflare origin certificates via Traefik cert resolver

## Configuration

### Docker Labels
Applied to `web` service in [docker-compose.yml](../docker-compose.yml):

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.glitchtip.rule=Host(`glitchtip.jefahnierocks.com`)"
  - "traefik.http.routers.glitchtip.entrypoints=websecure"
  - "traefik.http.routers.glitchtip.tls.certresolver=cloudflare"
  - "traefik.http.services.glitchtip.loadbalancer.server.port=8000"
  - "traefik.docker.network=traefik-public"
```

See [config/traefik/labels.yml](../config/traefik/labels.yml) for reference.

### Network Requirements
GlitchTip web service connects to two networks:
- `glitchtip-internal`: Internal service communication
- `proxy`: External network for Traefik routing

```yaml
networks:
  glitchtip-internal:
    driver: bridge
  proxy:
    external: true  # Must exist before deployment
```

## DNS Configuration
**Managed in:** Cloudflare (via `../hetzner` repo)

```
Type: A
Name: glitchtip.jefahnierocks.com
Value: [Hetzner Server IP]
Proxy: Enabled (orange cloud)
```

## TLS Certificate
- **Provider:** Cloudflare
- **Resolver:** `cloudflare` (configured in Traefik)
- **Type:** Origin certificate
- **Renewal:** Automatic via Traefik

## Verifying Routing

### Check Traefik Dashboard
If Traefik dashboard is enabled:
```
https://traefik.jefahnierocks.com/dashboard/
```

### Verify Service Registration
```bash
docker logs traefik | grep glitchtip
```

### Test Endpoint
```bash
curl -I https://glitchtip.jefahnierocks.com
```

Expected: `HTTP/2 200` or redirect to login

## Troubleshooting

### Service Not Reachable
1. Verify `proxy` network exists:
   ```bash
   docker network ls | grep proxy
   ```

2. Verify web service is on network:
   ```bash
   docker inspect glitchtip-web | grep -A 10 Networks
   ```

3. Check Traefik can see service:
   ```bash
   docker logs traefik | tail -50
   ```

### TLS Certificate Issues
1. Check cert resolver in Traefik config (see `../hetzner`)
2. Verify Cloudflare API token has correct permissions
3. Check Traefik logs for ACME errors:
   ```bash
   docker logs traefik | grep -i acme
   ```

### DNS Resolution
```bash
dig glitchtip.jefahnierocks.com +short
# Should return Cloudflare proxy IPs or server IP if unproxied
```

## See Also
- [01-architecture.md](./01-architecture.md) - Network architecture
- [02-deployment.md](./02-deployment.md) - Deployment steps
- `../hetzner` - Traefik deployment and configuration
