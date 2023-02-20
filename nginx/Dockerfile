FROM docker.io/library/nginx:1.23.3-alpine-slim

COPY --chown=nginx:nginx ./nginx.conf /etc/nginx/nginx.conf

COPY --chown=nginx:nginx ./www /srv/www
