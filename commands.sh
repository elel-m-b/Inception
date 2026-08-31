```text
============================================================
42 INCEPTION - COMPLETE TEST COMMANDS
============================================================


============================================================
1. DOCKER COMPOSE
============================================================

# Check containers
sudo docker compose ps

# Check all containers
sudo docker ps

# Check stopped containers
sudo docker ps -a

# Check images
sudo docker images

# Check volumes
sudo docker volume ls

# Check networks
sudo docker network ls


============================================================
2. BUILD
============================================================

# Build everything
sudo docker compose build

# Build without cache
sudo docker compose build --no-cache

# Build and start
sudo docker compose up --build -d


============================================================
3. START / STOP
============================================================

# Start
sudo docker compose up -d

# Stop containers
sudo docker compose stop

# Start stopped containers
sudo docker compose start

# Restart everything
sudo docker compose restart

# Stop and remove containers/networks
sudo docker compose down


============================================================
4. IMPORTANT: DO NOT DELETE VOLUMES
============================================================

# DO NOT normally use:
sudo docker compose down -v

# -v removes Docker volumes.


============================================================
5. CONTAINER STATUS
============================================================

# Check status
sudo docker compose ps

# Check one container
sudo docker inspect mariadb
sudo docker inspect wordpress
sudo docker inspect nginx


============================================================
6. LOGS
============================================================

# All logs
sudo docker compose logs

# MariaDB logs
sudo docker compose logs mariadb

# WordPress logs
sudo docker compose logs wordpress

# Nginx logs
sudo docker compose logs nginx

# Last 50 lines
sudo docker compose logs --tail=50 mariadb
sudo docker compose logs --tail=50 wordpress
sudo docker compose logs --tail=50 nginx

# Follow logs live
sudo docker compose logs -f mariadb
sudo docker compose logs -f wordpress
sudo docker compose logs -f nginx


============================================================
7. ENTER CONTAINERS
============================================================

# MariaDB
sudo docker compose exec mariadb bash

# WordPress
sudo docker compose exec wordpress bash

# Nginx
sudo docker compose exec nginx bash


============================================================
8. MARIADB
============================================================

# Connect as root
mariadb -u root -p

# Show databases
SHOW DATABASES;

# Select WordPress database
USE wordpress;

# Show tables
SHOW TABLES;

# Show users
SELECT User, Host FROM mysql.user;

# Show WordPress user privileges
SHOW GRANTS FOR 'wpuser'@'%';

# Check current user
SELECT USER();

# Check current database
SELECT DATABASE();

# Check MariaDB version
SELECT VERSION();

# Exit
EXIT;


============================================================
9. TEST WORDPRESS USER
============================================================

# From MariaDB container
mariadb -u wpuser -p wordpress

# Test with host
mariadb -h localhost -u wpuser -p wordpress

# Test from WordPress container
mariadb -h mariadb -u wpuser -p wordpress

# Test query
mariadb -h mariadb -u wpuser -p wordpress \
-e "SELECT DATABASE(), USER(), VERSION();"


============================================================
10. TEST DATABASE FROM WORDPRESS
============================================================

# Enter WordPress
sudo docker compose exec wordpress bash

# DNS test
getent hosts mariadb

# MariaDB port test
bash -c 'cat < /dev/null > /dev/tcp/mariadb/3306' \
&& echo "3306 OPEN" \
|| echo "3306 CLOSED"

# Connect to MariaDB
mariadb -h mariadb -u wpuser -p wordpress


============================================================
11. WORDPRESS CONFIGURATION
============================================================

# Check wp-config.php
cat /var/www/html/wp-config.php

# Check only database settings
grep -E "DB_NAME|DB_USER|DB_PASSWORD|DB_HOST" \
/var/www/html/wp-config.php

# DB_HOST should normally be:
# mariadb


============================================================
12. WORDPRESS FILES
============================================================

# Check WordPress directory
ls -lah /var/www/html

# Check wp-config.php
ls -l /var/www/html/wp-config.php

# Check index.php
ls -l /var/www/html/index.php

# Check WordPress core
wp core version --allow-root


============================================================
13. WORDPRESS WP-CLI
============================================================

# Check installation
wp core is-installed --allow-root

# Check WordPress version
wp core version --allow-root

# Check database
wp db check --allow-root

# Show database tables
wp db tables --allow-root

# Show WordPress users
wp user list --allow-root

# Show WordPress options
wp option get siteurl --allow-root
wp option get home --allow-root

# Check WordPress status
wp core status --allow-root


============================================================
14. PHP-FPM
============================================================

# Check PHP version
php -v

# Check PHP-FPM process
ps aux | grep php-fpm

# Check PHP-FPM listening port
ss -lntp | grep 9000

# Check PHP-FPM configuration
grep -E "^listen" /etc/php/*/fpm/pool.d/www.conf


============================================================
15. NGINX
============================================================

# Check Nginx version
nginx -v

# Test Nginx configuration
nginx -t

# Check Nginx configuration
cat /etc/nginx/nginx.conf

# Check sites configuration
ls -lah /etc/nginx/conf.d/


============================================================
16. NGINX -> WORDPRESS / PHP-FPM
============================================================

# Check port 9000 from Nginx
bash -c 'cat < /dev/null > /dev/tcp/wordpress/9000' \
&& echo "PHP-FPM 9000 OPEN" \
|| echo "PHP-FPM 9000 CLOSED"

# Resolve WordPress container
getent hosts wordpress


============================================================
17. SSL / TLS
============================================================

# Check certificate files
ls -lah /etc/nginx/ssl/

# Check HTTPS
curl -k -I https://localhost

# Check HTTP status
curl -k -L -s -o /dev/null \
-w "HTTP Status: %{http_code}\n" \
https://localhost

# Show certificate
openssl s_client -connect localhost:443 \
-servername localhost </dev/null

# Check certificate dates
openssl x509 -in /etc/nginx/ssl/*.crt \
-noout -dates

# Check certificate subject
openssl x509 -in /etc/nginx/ssl/*.crt \
-noout -subject


============================================================
18. TEST WEBSITE
============================================================

# Headers
curl -k -I https://localhost

# Follow redirects
curl -k -L https://localhost

# Only HTTP status
curl -k -L -s -o /dev/null \
-w "%{http_code}\n" \
https://localhost


============================================================
19. DOCKER NETWORK
============================================================

# List networks
sudo docker network ls

# Inspect network
sudo docker network inspect inception_inception

# Check MariaDB network
sudo docker inspect mariadb \
--format '{{range $name, $network := .NetworkSettings.Networks}}{{$name}} -> {{$network.IPAddress}}{{println}}'

# Check WordPress network
sudo docker inspect wordpress \
--format '{{range $name, $network := .NetworkSettings.Networks}}{{$name}} -> {{$network.IPAddress}}{{println}}'

# Check Nginx network
sudo docker inspect nginx \
--format '{{range $name, $network := .NetworkSettings.Networks}}{{$name}} -> {{$network.IPAddress}}{{println}}'


============================================================
20. TEST CONTAINER CONNECTIVITY
============================================================

# WordPress -> MariaDB
sudo docker compose exec wordpress getent hosts mariadb

# Nginx -> WordPress
sudo docker compose exec nginx getent hosts wordpress

# WordPress -> MariaDB port
sudo docker compose exec wordpress \
bash -c 'cat < /dev/null > /dev/tcp/mariadb/3306' \
&& echo "OPEN" || echo "CLOSED"

# Nginx -> PHP-FPM
sudo docker compose exec nginx \
bash -c 'cat < /dev/null > /dev/tcp/wordpress/9000' \
&& echo "OPEN" || echo "CLOSED"


============================================================
21. VOLUMES
============================================================

# List volumes
sudo docker volume ls

# Inspect volumes
sudo docker volume inspect <volume_name>

# Check container mounts
sudo docker inspect mariadb \
--format '{{range .Mounts}}{{.Type}} -> {{.Source}} -> {{.Destination}}{{println}}'

sudo docker inspect wordpress \
--format '{{range .Mounts}}{{.Type}} -> {{.Source}} -> {{.Destination}}{{println}}'


============================================================
22. CHECK HOST DATA DIRECTORIES
============================================================

# Check Inception data directory
ls -lah /home/$USER/data

# Check MariaDB data
ls -lah /home/$USER/data/mariadb

# Check WordPress data
ls -lah /home/$USER/data/wordpress

# Check ownership
ls -ld /home/$USER/data
ls -ld /home/$USER/data/mariadb
ls -ld /home/$USER/data/wordpress


============================================================
23. SECRETS
============================================================

# Check secrets directory
ls -lah ./secrets

# Check secret files
ls -l ./secrets

# Check MariaDB container secrets
sudo docker compose exec mariadb ls -lah /run/secrets

# Check WordPress container secrets
sudo docker compose exec wordpress ls -lah /run/secrets

# IMPORTANT:
# Do not print passwords with cat during normal testing.


============================================================
24. ENVIRONMENT VARIABLES
============================================================

# Check Compose environment
sudo docker compose config

# Check WordPress environment
sudo docker compose exec wordpress env

# Check only database-related variables
sudo docker compose exec wordpress \
env | grep -E 'MYSQL|MARIADB|WORDPRESS|DB_'


============================================================
25. DOCKER COMPOSE CONFIGURATION
============================================================

# Validate Compose file
sudo docker compose config

# Show resolved configuration
sudo docker compose config --services

# Show service names
sudo docker compose config --services


============================================================
26. PROCESS TESTS
============================================================

# MariaDB processes
sudo docker compose exec mariadb ps aux

# WordPress processes
sudo docker compose exec wordpress ps aux

# Nginx processes
sudo docker compose exec nginx ps aux


============================================================
27. PORT TESTS
============================================================

# Host ports
sudo ss -lntp

# HTTPS 443
sudo ss -lntp | grep :443

# MariaDB 3306
sudo ss -lntp | grep :3306

# PHP-FPM 9000
sudo ss -lntp | grep :9000


============================================================
28. CONTAINER PORTS
============================================================

# MariaDB
sudo docker port mariadb

# WordPress
sudo docker port wordpress

# Nginx
sudo docker port nginx


============================================================
29. RESTART TEST
============================================================

# Restart all
sudo docker compose restart

# Check
sudo docker compose ps

# Check logs
sudo docker compose logs --tail=50


============================================================
30. DATABASE PERSISTENCE TEST
============================================================

# Before stopping
sudo docker compose exec mariadb \
mariadb -u root -p wordpress -e "SHOW TABLES;"

# Stop containers
sudo docker compose down

# Start again
sudo docker compose up -d

# Wait for MariaDB
sudo docker compose logs mariadb

# Check tables again
sudo docker compose exec mariadb \
mariadb -u root -p wordpress -e "SHOW TABLES;"


============================================================
31. WORDPRESS PERSISTENCE TEST
============================================================

# Check WordPress files
sudo docker compose exec wordpress \
ls -lah /var/www/html

# Check wp-config.php
sudo docker compose exec wordpress \
ls -l /var/www/html/wp-config.php

# Restart containers
sudo docker compose restart

# Check again
sudo docker compose exec wordpress \
ls -l /var/www/html/wp-config.php


============================================================
32. FULL REBUILD TEST
============================================================

# Remove containers
sudo docker compose down

# Rebuild images
sudo docker compose build --no-cache

# Start
sudo docker compose up -d

# Check
sudo docker compose ps

# Check logs
sudo docker compose logs --tail=50


============================================================
33. CHECK DOCKERFILE
============================================================

# MariaDB Dockerfile
cat mariadb/Dockerfile

# WordPress Dockerfile
cat wordpress/Dockerfile

# Nginx Dockerfile
cat nginx/Dockerfile


============================================================
34. CHECK CONFIG FILES
============================================================

# Compose
cat docker-compose.yml

# Environment
cat .env

# MariaDB configuration
cat mariadb/conf/*

# MariaDB script
cat mariadb/tools/*

# WordPress script
cat wordpress/tools/*

# Nginx configuration
cat nginx/conf/*


============================================================
35. CHECK FILE PERMISSIONS
============================================================

# Project
ls -lah

# MariaDB
ls -lah mariadb/

# WordPress
ls -lah wordpress/

# Nginx
ls -lah nginx/

# Scripts
ls -l mariadb/tools/
ls -l wordpress/tools/

# Make scripts executable if needed
chmod +x mariadb/tools/*.sh
chmod +x wordpress/tools/*.sh


============================================================
36. CHECK CONTAINER HEALTH
============================================================

sudo docker inspect mariadb \
--format='{{.State.Health.Status}}'

sudo docker inspect wordpress \
--format='{{.State.Health.Status}}'

sudo docker inspect nginx \
--format='{{.State.Health.Status}}'


============================================================
37. CHECK RESOURCE USAGE
============================================================

# CPU / RAM
sudo docker stats

# Disk usage
sudo docker system df

# Detailed disk usage
sudo docker system df -v


============================================================
38. CHECK WORDPRESS DATABASE CONTENT
============================================================

# Number of tables
sudo docker compose exec mariadb \
mariadb -u root -p wordpress \
-e "SHOW TABLES;"

# WordPress users
sudo docker compose exec mariadb \
mariadb -u root -p wordpress \
-e "SELECT ID,user_login,user_email FROM wp_users;"

# Site URL
sudo docker compose exec mariadb \
mariadb -u root -p wordpress \
-e "SELECT option_name,option_value FROM wp_options WHERE option_name IN ('siteurl','home');"


============================================================
39. FINAL WEBSITE TEST
============================================================

# Container status
sudo docker compose ps

# Database
sudo docker compose exec mariadb \
mariadb -u root -p wordpress \
-e "SELECT 1;"

# WordPress database connection
sudo docker compose exec wordpress \
wp db check --allow-root

# WordPress installation
sudo docker compose exec wordpress \
wp core is-installed --allow-root

# Nginx configuration
sudo docker compose exec nginx nginx -t

# HTTPS
curl -k -I https://localhost

# Website status
curl -k -L -s -o /dev/null \
-w "HTTP Status: %{http_code}\n" \
https://localhost


============================================================
40. 42 INCEPTION FINAL CHECK
============================================================

[ ] Docker Compose works

[ ] MariaDB container running

[ ] WordPress container running

[ ] Nginx container running

[ ] MariaDB ready for connections

[ ] Database exists

[ ] WordPress user exists

[ ] WordPress user has privileges

[ ] WordPress -> MariaDB connection works

[ ] wp-config.php exists

[ ] DB_HOST = mariadb

[ ] WordPress is installed

[ ] WordPress database tables exist

[ ] PHP-FPM running

[ ] PHP-FPM listening on 9000

[ ] Nginx configuration valid

[ ] Nginx -> WordPress connection works

[ ] HTTPS works

[ ] SSL certificate exists

[ ] Docker network works

[ ] MariaDB volume exists

[ ] WordPress volume exists

[ ] Host data is under /home/login/data

[ ] Database survives container restart

[ ] WordPress data survives container restart

[ ] No passwords hardcoded in Dockerfiles/scripts

[ ] Secrets are available through /run/secrets

[ ] Containers restart correctly

[ ] Website opens correctly


============================================================
IMPORTANT
============================================================

# NEVER use this casually:
sudo docker compose down -v

# It removes volumes.

# Also avoid:
sudo docker system prune --volumes

# unless you intentionally want to delete unused volumes.

============================================================
```
