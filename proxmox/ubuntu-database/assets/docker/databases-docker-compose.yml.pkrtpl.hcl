version: '3'

volumes:
  mariadb:
  redis:

services:
  mariadb:
    image: docker.io/mariadb:10.6
    restart: unless-stopped
    ports:
      - 3306:3306
    volumes:
      - mariadb:/var/lib/mysql
    environment:
      MARIADB_ROOT_PASSWORD: "${database_mariadb_root_password}"
    healthcheck:
      test: [ "CMD", "healthcheck.sh", "--connect", "--innodb_initialized" ]
      start_period: 1m
      start_interval: 10s
      interval: 1m
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 300M

  redis:
    image: docker.io/redis:7.4-alpine
    command: /bin/sh -c "redis-server --requirepass $$REDIS_PASSWORD"
    restart: unless-stopped
    ports:
      - 6379:6379
    volumes:
      - redis:/data
    environment:
      REDIS_PASSWORD: "${database_redis_password}"
    healthcheck:
      test: [ "CMD", "redis-cli", "--raw", "incr", "ping" ]
      start_period: 1m
      start_interval: 10s
      interval: 1m
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 100M