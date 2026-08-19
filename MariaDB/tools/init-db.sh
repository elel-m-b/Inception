#!/bin/bash

if [ ! -d "/var/lib/mysql/mysql" ]; then

    echo "Initializing MariaDB..."

    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    mysqld_safe --skip-networking &

    sleep 5

    mariadb -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"

    mariadb -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"

    mariadb -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"

    mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"

    mariadb -e "FLUSH PRIVILEGES;"

    mariadb-admin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

fi

echo "Starting MariaDB..."

exec mysqld --user=mysql --bind-address=0.0.0.0