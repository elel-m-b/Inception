#!/bin/bash

# Read Docker secrets if available
if [ -f /run/secrets/db_password ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
fi
if [ -f /run/secrets/credentials.txt ]; then
    WP_USER_PASSWORD=$(cat /run/secrets/credentials.txt)
fi
if [ -f /run/secrets/admin.txt ]; then
    WP_ADMIN_PASSWORD=$(cat /run/secrets/admin.txt)
fi


# Create configuration if not present
if [ ! -f /var/www/html/wp-config.php ]; then
    wp core download --path=/var/www/html --allow-root

    wp config create \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb \
        --path=/var/www/html \
        --allow-root

    wp core install \
        --url=${WP_URL:-https://${DOMAIN_NAME}} \
        --title="Inception" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --path=/var/www/html \
        --allow-root

    wp user create ${WP_USER} ${WP_USER_EMAIL} \
        --role=author \
        --user_pass=${WP_USER_PASSWORD} \
        --path=/var/www/html \
        --allow-root
fi

sed -i 's|^listen = .*|listen = 9000|' \
    /etc/php/8.2/fpm/pool.d/www.conf

mkdir -p /run/php

exec php-fpm8.2 -F