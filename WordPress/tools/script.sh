#!/bin/bash
# Install WordPress only once
if [ ! -f /var/www/html/wp-config.php ]; then

    cd /var/www/html

    # Install WP-CLI
    wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        -O /usr/local/bin/wp
    chmod +x /usr/local/bin/wp

    # Download WordPress
    wp core download --allow-root

    # Create configuration
    wp config create --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --skip-check

    # Install WordPress
    wp core install --allow-root \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_LOGIN}" \
        --admin_password="$(cat /run/secrets/credentials)" \
        --admin_email="${WP_ADMIN_EMAIL}"

    # Create normal user
    wp user create --allow-root \
        "${WP_USER_LOGIN}" \
        "${WP_USER_EMAIL}" \
        --user_pass="${MYSQL_PASSWORD}"

    chown -R www-data:www-data /var/www/html
fi

sed -i 's|^listen = .*|listen = 9000|' \
    /etc/php/8.2/fpm/pool.d/www.conf

mkdir -p /run/php

exec php-fpm8.2 -F