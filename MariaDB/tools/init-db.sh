#!/bin/bash

# unset MYSQL_HOST

mkdir -p /run/mysqld
chown -R mysql:mysql /var/lib/mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    mysqld_safe --skip-networking &
    pid="$!"

    until mariadb-admin --protocol=socket ping --silent; do
        sleep 1
    done

    mariadb --protocol=socket -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    mariadb-admin --protocol=socket shutdown -u root -p"${MYSQL_ROOT_PASSWORD}" 2>/dev/null || kill "$pid"
    wait "$pid"
fi

exec mysqld --user=mysql --bind-address=0.0.0.0