#!/bin/bash

set -e

echo "Initializing MariaDB..."

# Unset MYSQL_HOST for local socket operations inside init-db.sh
saved_mysql_host="${MYSQL_HOST}"
unset MYSQL_HOST

chown -R mysql:mysql /var/lib/mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then

    echo "Creating database directory structure..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    mysqld_safe --skip-networking &
    pid="$!"

    echo "Waiting for MariaDB temporary server..."

    until mariadb-admin --protocol=socket --socket=/run/mysqld/mysqld.sock -u root ping --silent; do
        sleep 1
    done

    echo "Setting up database and users..."
    mariadb --protocol=socket --socket=/run/mysqld/mysqld.sock -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

FLUSH PRIVILEGES;
EOF

    echo "Shutting down temporary MariaDB server..."
    mariadb-admin --protocol=socket --socket=/run/mysqld/mysqld.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait "$pid"
    echo "MariaDB initial configuration complete."

fi

unset MYSQL_HOST

echo "Starting MariaDB main process..."

exec mysqld --user=mysql --bind-address=0.0.0.0