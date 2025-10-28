# Architecture Overview

## System Components

### Application Stack
- **GlitchTip**: Error tracking application (latest)
- **PostgreSQL**: 15-alpine (primary datastore)
- **Redis**: 7-alpine (cache + Celery broker)
- **Traefik**: Reverse proxy with Cloudflare TLS

### Service Layout
```
                                   Internet
                                      |
                                  Cloudflare
                                      |
                        [Hetzner Server - Ubuntu 24.04]
                                      |
                                   Traefik
                            (traefik-public network)
                                      |
                           glitchtip.jefahnierocks.com
                                      |
                    +------------------+------------------+
                    |                                     |
              GlitchTip Web                    glitchtip-internal
             (port 8000)                            network
                    |                                     |
        +-----------+----------+                         |
        |           |          |                         |
    Worker       Beat      Redis                    PostgreSQL
  (Celery)   (Scheduler)  (Cache)                  (Primary DB)
```

## Resource Requirements
- **CPU**: 1 vCPU minimum (2 vCPU recommended)
- **RAM**: 1GB minimum (2GB recommended)
- **Storage**: ~30GB per million events
- **Network**: Cloudflare proxy (DDoS protection)

## Related Repositories
- `../hetzner`: Server provisioning, Traefik deployment
- `../infisical`: Secret management and sync
- This repo: GlitchTip application configuration

## Data Flow
1. Client SDKs send errors to `glitchtip.jefahnierocks.com`
2. Traefik routes traffic to web service (port 8000)
3. Web service writes to PostgreSQL, queues tasks to Redis
4. Worker processes async tasks (email, cleanup)
5. Beat schedules periodic tasks

## See Also
- [02-deployment.md](./02-deployment.md) - Deployment steps
- [04-traefik.md](./04-traefik.md) - Traefik integration
- [docker-compose.yml](../docker-compose.yml) - Service definitions
