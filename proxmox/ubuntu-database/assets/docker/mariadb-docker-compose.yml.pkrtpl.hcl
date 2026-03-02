version: '3'

volumes:
  mariadb:

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
