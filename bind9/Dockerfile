FROM docker.io/internetsystemsconsortium/bind9:9.18

RUN mkdir /var/named

COPY --chown=bind:bind ./named.conf /etc/bind/named.conf
COPY --chown=bind:bind ./milo.king.com.zone /var/named/milo.king.com.zone
