#!/bin/bash

# Read Docker secrets if available
if [ -f /run/secrets/db_password ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
fi
if [ -f /run/secrets/db_root_password ]; then
    MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
fi


# 1. Create /run/mysqld
# 2. Set permissions
# 3. Start temporary server for setup if database does not exist
# 4. Create database
# 5. Create user
# 6. Configure permissions
# 7. Start mysqld

mkdir -p /run/mysqld
chown -R mysql:mysql /var/lib/mysql /run/mysqld

# if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
#     mariadbd-safe --datadir=/var/lib/mysql &
#     while ! mariadb-admin --socket=/run/mysqld/mysqld.sock -u root ping --silent; do
#         sleep 1
#     done

    mariadb --socket=/run/mysqld/mysqld.sock -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%'
IDENTIFIED BY '${MYSQL_PASSWORD}';

ALTER USER '${MYSQL_USER}'@'%'
IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* 
TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost'
IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

FLUSH PRIVILEGES;
EOF

    # mariadb-admin --socket=/run/mysqld/mysqld.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
#     # wait
# fi

# Start MariaDB normally
exec mysqld --user=mysql --bind-address=0.0.0.0