# MariaDB

## 1. Objective

The goal of this step is to build and run a MariaDB service independently before integrating it with WordPress and NGINX.

By the end of this step, MariaDB must:

* Build successfully from a custom Dockerfile.
* Run inside a Docker container.
* Initialize a database.
* Create a database user.
* Set passwords for root and the application user.
* Grant the application user access to the WordPress database.
* Listen on port `3306`.
* Keep running as the main container process.
* Be ready to be connected to by WordPress later.
* Persist its database data using a Docker volume in the final Compose setup.

---

Therefore the build path must use:

```bash
./src/requirements/MariaDB
```
---

# 3. MariaDB Architecture

At this stage we only have MariaDB:

```text
Host
 │
 │ docker build
 ↓
MariaDB Docker Image
 │
 │ docker run
 ↓
MariaDB Container
 │
 ├── MariaDB Server
 │
 └── /var/lib/mysql
```

Later, the complete Inception architecture will be:

```text
                    Internet
                       │
                       ↓
                  ┌─────────┐
                  │  NGINX  │
                  │  :443   │
                  └────┬────┘
                       │
                       ↓
                ┌─────────────┐
                │  WordPress  │
                │   PHP-FPM   │
                └──────┬──────┘
                       │
                       ↓
                ┌─────────────┐
                │   MariaDB   │
                │    :3306    │
                └──────┬──────┘
                       │
                       ↓
                    Volume
```

The final communication will be:

```text
Browser
   ↓
NGINX
   ↓
WordPress
   ↓
MariaDB
```

---

# 4. Dockerfile

File:

```text
src/requirements/MariaDB/Dockerfile
```

```dockerfile
FROM debian:12

RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/mysqld && \
    chown mysql:mysql /run/mysqld

COPY tools/init-db.sh /usr/local/bin/init-db.sh

RUN chmod +x /usr/local/bin/init-db.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init-db.sh"]
```

---

# 5. Explanation of the Dockerfile

## `FROM`

```dockerfile
FROM debian:12
```

Starts the image from Debian 12.

The result is:

```text
Debian 12
   ↓
Install MariaDB
   ↓
Custom MariaDB image
```

---

## Install MariaDB

```dockerfile
RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/*
```

This:

1. Updates Debian package information.
2. Installs MariaDB Server.
3. Removes package metadata to reduce image size.

Important:

```text
Installed ≠ Running
```

The Dockerfile installs MariaDB, but the container still needs to start the MariaDB server.

---

## Create `/run/mysqld`

```dockerfile
RUN mkdir -p /run/mysqld && \
    chown mysql:mysql /run/mysqld
```

MariaDB needs:

```text
/run/mysqld/mysqld.sock
```

for its Unix socket.

Without `/run/mysqld`, MariaDB can fail with:

```text
Can't start server : Bind on unix socket:
No such file or directory
```

This was the error encountered during testing.

The fix is:

```text
/run/mysqld
      ↓
owned by mysql:mysql
      ↓
MariaDB can create mysqld.sock
```

---

## COPY

```dockerfile
COPY tools/init-db.sh /usr/local/bin/init-db.sh
```

Copies the initialization script from the project into the Docker image.

From:

```text
src/requirements/MariaDB/tools/init-db.sh
```

to:

```text
/usr/local/bin/init-db.sh
```

inside the image.

---

## chmod

```dockerfile
RUN chmod +x /usr/local/bin/init-db.sh
```

Makes the script executable.

---

## EXPOSE

```dockerfile
EXPOSE 3306
```

Documents that MariaDB uses port `3306`.

Important:

`EXPOSE` does not publish the port to the host.

It does not mean:

```text
Host:3306 → Container:3306
```

It only declares the container port.

---

## ENTRYPOINT

```dockerfile
ENTRYPOINT ["/usr/local/bin/init-db.sh"]
```

When the container starts:

```text
Container starts
      ↓
init-db.sh
      ↓
Initialize MariaDB
      ↓
Create database
      ↓
Create user
      ↓
Start mysqld
```

---

# 6. Initialization Script

File:

```text
src/requirements/MariaDB/tools/init-db.sh
```

```bash
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
```

---

# 7. Explanation of `init-db.sh`

## Bash

```bash
#!/bin/bash
```

Tells Linux to execute the script using Bash.

---

## Stop on errors

```bash
set -e
```

If a command fails, the script stops.

This prevents MariaDB from continuing with a broken initialization.

---

## MariaDB data directory

```bash
DATADIR="/var/lib/mysql"
```

MariaDB stores its database files inside:

```text
/var/lib/mysql
```

For example:

```text
/var/lib/mysql/
├── mysql/
├── performance_schema/
├── sys/
└── wordpress/
```

---

# 8. Detect First Initialization

```bash
if [ ! -d "$DATADIR/mysql" ]; then
```

Checks whether MariaDB has already been initialized.

If the system tables do not exist:

```text
First start
    ↓
Initialize MariaDB
```

If they already exist:

```text
Existing database
    ↓
Skip initialization
```

This becomes especially important when a Docker volume is used.

---

# 9. Initialize MariaDB

```bash
mariadb-install-db --user=mysql --datadir="$DATADIR"
```

Creates MariaDB's initial system tables.

Conceptually:

```text
Empty /var/lib/mysql
        ↓
mariadb-install-db
        ↓
MariaDB system tables
```

---

# 10. Start MariaDB Temporarily

```bash
mysqld_safe --skip-networking &
```

MariaDB is started temporarily so that SQL commands can be executed.

`&` means the process runs in the background.

The script can therefore continue.

---

# 11. Wait Until MariaDB Is Ready

```bash
until mariadb-admin ping --silent; do
    sleep 1
done
```

MariaDB may need some time before accepting connections.

The script waits:

```text
Start MariaDB
      ↓
Ready?
  │
  ├── No → wait 1 second
  │
  └── Yes
       ↓
Continue
```

This avoids trying to create the database before MariaDB is ready.

---

# 12. Create Database

```sql
CREATE DATABASE IF NOT EXISTS `${MYSQL_DATABASE}`;
```

If:

```text
MYSQL_DATABASE=wordpress
```

this becomes:

```sql
CREATE DATABASE IF NOT EXISTS `wordpress`;
```

---

# 13. Create User

```sql
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
```

If:

```text
MYSQL_USER=wpuser
MYSQL_PASSWORD=wpsecret
```

the result is:

```sql
CREATE USER 'wpuser'@'%' IDENTIFIED BY 'wpsecret';
```

`%` allows the user to connect from other hosts, which is useful when WordPress runs in another Docker container.

---

# 14. Grant Permissions

```sql
GRANT ALL PRIVILEGES ON `${MYSQL_DATABASE}`.* TO '${MYSQL_USER}'@'%';
```

This gives the application user permissions on the WordPress database.

Conceptually:

```text
wpuser
   ↓
wordpress database
   ↓
ALL PRIVILEGES
```

---

# 15. Set Root Password

```sql
ALTER USER 'root'@'localhost'
IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
```

Sets the root password.

---

# 16. Apply Privileges

```sql
FLUSH PRIVILEGES;
```

Refreshes MariaDB privilege information.

---

# 17. Stop Temporary Server

```bash
mariadb-admin shutdown -u root -p"${MYSQL_ROOT_PASSWORD}"
```

The temporary MariaDB process is stopped.

---

# 18. Start MariaDB Normally

```bash
exec mysqld --user=mysql --bind-address=0.0.0.0
```

This starts the actual MariaDB server.

`exec` replaces the shell process with `mysqld`.

This is important in Docker because `mysqld` becomes the main process of the container.

Conceptually:

```text
Container
    │
    └── PID 1
         │
         └── mysqld
```

If `mysqld` stops:

```text
mysqld stops
     ↓
Container stops
```

---

# 19. Build the Image

From the project root:

```bash
docker build -t mariadb:test ./src/requirements/MariaDB
```

If you want to force Docker to rebuild everything:

```bash
docker build --no-cache -t mariadb:test ./src/requirements/MariaDB
```

`--no-cache` is useful when debugging Dockerfile changes.

---

# 20. Check the Image

```bash
docker images | grep mariadb
```

Expected:

```text
mariadb    test    ...
```

---

# 21. Run MariaDB

For the initial standalone test:

```bash
docker run -d \
  --name mariadb \
  -e MYSQL_DATABASE=wordpress \
  -e MYSQL_USER=wpuser \
  -e MYSQL_PASSWORD=wpsecret \
  -e MYSQL_ROOT_PASSWORD=rootsecret \
  mariadb:test
```

Environment variables:

```text
MYSQL_DATABASE
    ↓
wordpress

MYSQL_USER
    ↓
wpuser

MYSQL_PASSWORD
    ↓
wpsecret

MYSQL_ROOT_PASSWORD
    ↓
rootsecret
```

---

# 22. Check Container Status

```bash
docker ps
```

Expected:

```text
CONTAINER ID   IMAGE          COMMAND                  STATUS       PORTS      NAMES
...            mariadb:test   "/usr/local/bin/init…"   Up ...       3306/tcp   mariadb
```

The most important part is:

```text
Up
```

If the container is not running:

```bash
docker ps -a
```

Then inspect:

```bash
docker logs mariadb
```

---

# 23. Check MariaDB Logs

```bash
docker logs mariadb
```

A successful startup should contain:

```text
mysqld: ready for connections.
```

For example:

```text
Server socket created on IP: '0.0.0.0', port: '3306'.
mysqld: ready for connections.
Version: '10.11.18-MariaDB-0+deb12u1'
socket: '/run/mysqld/mysqld.sock'
port: 3306
```

This confirms:

* MariaDB started.
* Socket exists.
* Port `3306` is active.
* MariaDB is ready for connections.

---

# 24. Important Warning in the Logs

You may see:

```text
io_uring_queue_init() failed with EPERM
```

followed by:

```text
falling back to libaio
```

This is not the main failure.

MariaDB automatically falls back to another I/O mechanism.

The important line is:

```text
mysqld: ready for connections.
```

---

# 25. Connect as Root

Only run this after:

```bash
docker ps
```

shows the container as `Up`.

Command:

```bash
docker exec -it mariadb mariadb -u root -p
```

Enter:

```text
rootsecret
```

Expected:

```text
Welcome to the MariaDB monitor.
MariaDB [(none)]>
```

---

# 26. Important: MariaDB Shell vs Linux Shell

When you see:

```text
MariaDB [(none)]>
```

you are inside the MariaDB SQL shell.

Commands such as:

```text
ls
```

are Linux commands, not SQL commands.

For example:

```sql
SHOW DATABASES;
```

is valid MariaDB SQL.

To leave MariaDB:

```sql
quit;
```

or:

```sql
exit;
```

Then you return to the normal Linux shell:

```text
➜ Inception git:(main) $
```

---

# 27. Test Database Creation

Inside MariaDB:

```sql
SHOW DATABASES;
```

Expected to contain:

```text
wordpress
```

Example:

```text
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| wordpress          |
+--------------------+
```

Result:

```text
Database creation: PASS
```

---

# 28. Test User Creation

Inside MariaDB:

```sql
SELECT User, Host FROM mysql.user;
```

Expected:

```text
wpuser    %
```

Result:

```text
User creation: PASS
```

---

# 29. Test User Permissions

Run:

```sql
SHOW GRANTS FOR 'wpuser'@'%';
```

Expected to see privileges on:

```text
wordpress
```

For example:

```text
GRANT ALL PRIVILEGES ON `wordpress`.* ...
```

Result:

```text
Permissions: PASS
```

---

# 30. Test User Login

Exit:

```sql
quit;
```

Then:

```bash
docker exec -it mariadb mariadb -u wpuser -p
```

Enter:

```text
wpsecret
```

Expected:

```text
MariaDB [(none)]>
```

Result:

```text
User authentication: PASS
```

---

# 31. Test Database Access

While logged in as `wpuser`:

```sql
USE wordpress;
```

Expected:

```text
Database changed
```

---

# 32. Test CREATE Permission

Run:

```sql
CREATE TABLE test (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);
```

Then:

```sql
SHOW TABLES;
```

Expected:

```text
test
```

Result:

```text
CREATE permission: PASS
```

---

# 33. Test INSERT Permission

```sql
INSERT INTO test VALUES (1, 'Hassan');
```

---

# 34. Test SELECT Permission

```sql
SELECT * FROM test;
```

Expected:

```text
+----+--------+
| id | name   |
+----+--------+
|  1 | Hassan |
+----+--------+
```

This proves:

```text
CREATE  → PASS
INSERT  → PASS
SELECT  → PASS
```

---

# 35. Test MariaDB Port

Exit MariaDB:

```sql
quit;
```

Then:

```bash
docker exec mariadb ss -lntp
```

MariaDB should be listening on:

```text
3306
```

The container should also show:

```text
3306/tcp
```

with:

```bash
docker ps
```

---

# 36. Test the MariaDB Process

Run:

```bash
docker exec mariadb ps aux
```

You should find:

```text
mysqld
```

This confirms that the MariaDB server is actually running inside the container.

---

# 37. Troubleshooting

## Container is not running

If:

```bash
docker exec -it mariadb ...
```

returns:

```text
container ... is not running
```

Do not try `docker exec` again.

First:

```bash
docker ps -a
```

Then:

```bash
docker logs mariadb
```

The logs explain why the container stopped.

---

## MariaDB socket error

If you see:

```text
Can't start server : Bind on unix socket:
No such file or directory
```

Make sure the Dockerfile contains:

```dockerfile
RUN mkdir -p /run/mysqld && \
    chown mysql:mysql /run/mysqld
```

Then rebuild:

```bash
docker rm mariadb
```

```bash
docker build --no-cache -t mariadb:test ./src/requirements/MariaDB
```

Run the container again.

---

# 38. Complete Clean Test

To restart the standalone test from zero:

```bash
docker rm -f mariadb
```

Build:

```bash
docker build --no-cache -t mariadb:test ./src/requirements/MariaDB
```

Run:

```bash
docker run -d \
  --name mariadb \
  -e MYSQL_DATABASE=wordpress \
  -e MYSQL_USER=wpuser \
  -e MYSQL_PASSWORD=wpsecret \
  -e MYSQL_ROOT_PASSWORD=rootsecret \
  mariadb:test
```

Check:

```bash
docker ps
```

Logs:

```bash
docker logs mariadb
```

Connect:

```bash
docker exec -it mariadb mariadb -u root -p
```

Then:

```sql
SHOW DATABASES;
```

```sql
SELECT User, Host FROM mysql.user;
```

```sql
SHOW GRANTS FOR 'wpuser'@'%';
```

Exit:

```sql
quit;
```

Login as application user:

```bash
docker exec -it mariadb mariadb -u wpuser -p
```

Then:

```sql
USE wordpress;
```

```sql
CREATE TABLE test (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);
```

```sql
INSERT INTO test VALUES (1, 'Hassan');
```

```sql
SELECT * FROM test;
```

---

# 39. Current Test Results

Based on the current test session:

```text
Dockerfile build              PASS
MariaDB image                 PASS
Container creation            PASS
Container running             PASS
MariaDB process               PASS
MariaDB socket                PASS
Port 3306                     PASS
MariaDB ready for connections PASS
Root login                    PASS
```

The remaining tests are:

```text
Database creation             TODO
User creation                 TODO
User permissions              TODO
Application user login        TODO
CREATE/INSERT/SELECT          TODO
Persistent volume             TODO
```

---

# 40. MariaDB Step Completion Checklist

Before considering this step complete:

* [ ] MariaDB Dockerfile builds successfully.
* [ ] MariaDB container starts successfully.
* [ ] Container remains `Up`.
* [ ] `mysqld` is running.
* [ ] `/run/mysqld/mysqld.sock` exists.
* [ ] MariaDB listens on port `3306`.
* [ ] Root can authenticate.
* [ ] `wordpress` database exists.
* [ ] `wpuser` exists.
* [ ] `wpuser` has privileges on `wordpress`.
* [ ] `wpuser` can authenticate.
* [ ] `wpuser` can create tables.
* [ ] `wpuser` can insert data.
* [ ] `wpuser` can read data.
* [ ] MariaDB data is stored in a Docker volume.
* [ ] Data survives container restart.
* [ ] Data survives container recreation when the volume is preserved.

---

# 41. Final Concept

The complete MariaDB flow is:

```text
Dockerfile
     │
     │ docker build
     ↓
MariaDB Image
     │
     │ docker run
     ↓
MariaDB Container
     │
     ↓
ENTRYPOINT
     │
     ↓
init-db.sh
     │
     ├── Initialize MariaDB
     │
     ├── Create database
     │
     ├── Create user
     │
     ├── Grant privileges
     │
     └── Start mysqld
             │
             ↓
       MariaDB :3306
             │
             ↓
       Docker Volume
```

Later:

```text
NGINX
  │
  ↓
WordPress
  │
  ↓
MariaDB :3306
  │
  ↓
/var/lib/mysql
  │
  ↓
Docker Volume
```

The key principle is:

> **The container provides the MariaDB service, while the Docker volume provides persistent database storage.**
