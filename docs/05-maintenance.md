# Maintenance & Operations

## Routine Operations

### Health Checks
```bash
# Service status
docker compose ps

# Service health
docker compose exec web ./manage.py check

# Recent logs
docker compose logs --tail=100 --follow web
```

### Database Maintenance
```bash
# Database size
docker compose exec postgres psql -U glitchtip_maintainer -d glitchtip \
  -c "SELECT pg_size_pretty(pg_database_size('glitchtip'));"

# Connection count
docker compose exec postgres psql -U glitchtip_maintainer -d glitchtip \
  -c "SELECT count(*) FROM pg_stat_activity;"

# Vacuum (optional, runs automatically)
docker compose exec postgres psql -U glitchtip_maintainer -d glitchtip \
  -c "VACUUM ANALYZE;"
```

### Log Management
```bash
# Web service logs
docker compose logs web

# Worker logs
docker compose logs worker

# All services
docker compose logs

# Follow logs
docker compose logs -f
```

## Backups

### Automated Backup
Use [scripts/backup.sh](../scripts/backup.sh):
```bash
./scripts/backup.sh
```

Creates timestamped backup in `/opt/glitchtip/backups/`.

### Manual Database Backup
```bash
docker compose exec postgres pg_dump -U glitchtip_maintainer glitchtip \
  | gzip > backup-$(date +%Y%m%d-%H%M%S).sql.gz
```

### Backup Schedule (cron)
```cron
# Daily backup at 2 AM
0 2 * * * cd /opt/glitchtip && ./scripts/backup.sh
```

### Restore from Backup
```bash
# Stop services
docker compose down

# Restore database
gunzip < backup-YYYYMMDD-HHMMSS.sql.gz | \
  docker compose exec -T postgres psql -U glitchtip_maintainer glitchtip

# Start services
docker compose up -d
```

## Monitoring

### Key Metrics
- **Event ingestion rate**: Monitor via GlitchTip UI
- **Database size**: Track growth over time
- **Response time**: Monitor via Traefik metrics (see `../hetzner`)
- **Error rate**: GlitchTip self-monitoring

### Disk Usage
```bash
# Docker volumes
docker system df -v

# Specific volume
docker volume inspect glitchtip_pgdata
```

### Performance Tuning
Adjust in [docker-compose.yml](../docker-compose.yml):
- `UWSGI_WORKERS`: Web concurrency (default: 4)
- `CELERY_WORKER_CONCURRENCY`: Background job concurrency (default: 2)

## Upgrades

### Application Upgrade
```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d

# Verify
docker compose logs web | head -20
```

Migrations run automatically on container start.

### PostgreSQL Upgrade
Major version upgrades require data migration:
1. Backup database (see above)
2. Update image version in `docker-compose.yml`
3. Stop services: `docker compose down`
4. Remove old volume: `docker volume rm glitchtip_pgdata`
5. Start services: `docker compose up -d`
6. Restore backup if needed

## Troubleshooting

### Service Won't Start
```bash
# Check logs
docker compose logs service-name

# Inspect container
docker compose ps
docker inspect glitchtip-web
```

### Database Connection Issues
```bash
# Verify database is healthy
docker compose exec postgres pg_isready -U glitchtip_maintainer

# Check DATABASE_URL format
docker compose exec web env | grep DATABASE_URL
```

### High Memory Usage
```bash
# Check container stats
docker stats

# Adjust worker counts in docker-compose.yml
# Restart: docker compose up -d
```

### Event Data Cleanup
Configured via `GLITCHTIP_MAX_EVENT_LIFE_DAYS` (default: 90 days).

Manual cleanup:
```bash
docker compose exec web ./manage.py cleanup_old_events
```

## Resource Limits

Add to services in docker-compose.yml if needed:
```yaml
deploy:
  resources:
    limits:
      cpus: '1'
      memory: 1G
    reservations:
      memory: 512M
```

## Support & Donation

GlitchTip is open-source. Consider donating to support development:
- **Recommended**: $5/user/month
- **Contact**: sales@glitchtip.com
- **License**: MIT (commercial use allowed)

## See Also
- [02-deployment.md](./02-deployment.md) - Initial deployment
- [03-secrets.md](./03-secrets.md) - Secret rotation
- [scripts/backup.sh](../scripts/backup.sh) - Backup automation
- [scripts/deploy.sh](../scripts/deploy.sh) - Deployment automation
