#!/bin/bash

set -e

DATADIR="/var/lib/mysql"

if [ ! -d "$DATADIR/mysql" ]; then
    echo "Initializing MariaDB..."

    mariadb-install-db --user=mysql --datadir="$DATADIR"

    mysqld_safe --skip-networking &
    pid="$!"

    echo "Waiting for MariaDB..."
    until mariadb-admin ping --silent; do
        sleep 1
    done

    echo "Creating database and user..."

    mariadb <<-EOF
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
EOF

    mariadb-admin shutdown -u root -p"${MYSQL_ROOT_PASSWORD}"

    wait "$pid"
fi

echo "Starting MariaDB..."

exec mysqld --user=mysql --bind-address=0.0.0.0