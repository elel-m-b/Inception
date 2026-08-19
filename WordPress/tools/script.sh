#!/bin/bash

set -e

echo "Starting WordPress setup..."

# --------------------------------------------------
# 1. Wait for MariaDB
# --------------------------------------------------

echo "Waiting for MariaDB at host ${MYSQL_HOST}..."

until mysqladmin ping \
    -h"${MYSQL_HOST}" \
    -u"${MYSQL_USER}" \
    -p"${MYSQL_PASSWORD}" \
    --silent
do
    echo "MariaDB is not ready yet..."
    sleep 2
done

echo "MariaDB is ready!"

# --------------------------------------------------
# 2. Create wp-config.php
# --------------------------------------------------

if [ ! -f /var/www/html/wp-config.php ]; then

    echo "Creating wp-config.php..."

    wp config create \
        --path=/var/www/html \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${MYSQL_HOST}" \
        --allow-root

else

    echo "wp-config.php already exists."

fi

# --------------------------------------------------
# 3. Install WordPress
# --------------------------------------------------

if ! wp core is-installed \
    --path=/var/www/html \
    --allow-root
then

    echo "Installing WordPress..."

    wp core install \
        --path=/var/www/html \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

else

    echo "WordPress is already installed."

fi

# --------------------------------------------------
# 4. Fix permissions & Runtime directories
# --------------------------------------------------

mkdir -p /run/php
chown -R www-data:www-data /var/www/html

# --------------------------------------------------
# 5. Configure PHP-FPM
# --------------------------------------------------

sed -i 's|^listen = .*|listen = 9000|' \
    /etc/php/8.2/fpm/pool.d/www.conf

# --------------------------------------------------
# 6. Start PHP-FPM
# --------------------------------------------------

echo "Starting PHP-FPM..."

exec php-fpm8.2 -F