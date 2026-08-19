#!/bin/bash

set -e

echo "Starting NGINX..."

mkdir -p /etc/nginx/ssl

if [ ! -f /etc/nginx/ssl/server.crt ]; then
    echo "Creating SSL certificate..."

    openssl req -x509 \
        -nodes \
        -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/server.key \
        -out /etc/nginx/ssl/server.crt \
        -subj "/C=MA/ST=Rabat/L=Rabat/O=42/OU=Inception/CN=localhost"
fi

nginx -g "daemon off;"