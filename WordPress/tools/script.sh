#!/bin/bash

set -e

echo "Starting WordPress setup..."

MYSQL_HOST="${MYSQL_HOST:-mariadb}"
WP_URL="${WP_URL:-https://${DOMAIN_NAME:-localhost}}"
WP_TITLE="${WP_TITLE:-Inception}"

# --------------------------------------------------
# 1. Wait for MariaDB
# --------------------------------------------------

echo "Waiting for MariaDB at host ${MYSQL_HOST}:3306..."

max_retries=30
count=0

until mysqladmin ping \
    -h"${MYSQL_HOST}" \
    -u"${MYSQL_USER}" \
    -p"${MYSQL_PASSWORD}" \
    --silent
do
    count=$((count + 1))
    if [ "$count" -ge "$max_retries" ]; then
        echo "Error: MariaDB at ${MYSQL_HOST}:3306 is not reachable after ${max_retries} attempts." >&2
        exit 1
    fi
    echo "MariaDB is not ready yet... (attempt $count/$max_retries)"
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
# 3. Install WordPress & Create Users
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

if [ -n "${WP_USER}" ] && ! wp user get "${WP_USER}" --path=/var/www/html --allow-root > /dev/null 2>&1; then
    echo "Creating regular user ${WP_USER}..."
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --path=/var/www/html \
        --allow-root
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