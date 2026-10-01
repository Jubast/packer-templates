FROM docker.io/nextcloud:35.0.0-apache

# ffmpeg is required by Nextcloud's OC\Preview\Movie provider to generate
# video thumbnails; the upstream image does not include it.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*
