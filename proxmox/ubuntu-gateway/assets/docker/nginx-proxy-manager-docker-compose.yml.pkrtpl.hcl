version: '3'

volumes:
  nginx-proxy-manager-data:
  nginx-proxy-manager-letsencrypt:

services:
  nginx-proxy-manager:
    image: docker.io/jc21/nginx-proxy-manager:2.14.0
    restart: unless-stopped
    ports:
      - 80:80
      - 443:443
      - 8081:81
    volumes:
      - nginx-proxy-manager-data:/data
      - nginx-proxy-manager-letsencrypt:/etc/letsencrypt
    environment:
      DB_MYSQL_HOST: "${npm_db_mysql_host}"
      DB_MYSQL_PORT: "${npm_db_mysql_port}"
      DB_MYSQL_USER: "${npm_db_mysql_user}"
      DB_MYSQL_PASSWORD: "${npm_db_mysql_password}"
      DB_MYSQL_NAME: "${npm_db_mysql_name}"
    healthcheck:
      test: ["CMD", "/usr/bin/check-health"]
      start_period: 1m
      start_interval: 10s
      interval: 1m
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
