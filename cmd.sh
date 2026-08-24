docker compose ps

docker compose exec mariadb mariadb-admin ping -u root -p

docker compose exec mariadb mariadb -u root -p -e "SHOW DATABASES;"

docker compose exec wordpress wp core is-installed --path=/var/www/html --allow-root

docker compose exec wordpress wp db check --path=/var/www/html --allow-root

docker compose exec wordpress wp option get siteurl --path=/var/www/html --allow-root

docker compose exec nginx nginx -t

curl -k -I https://localhost

docker compose exec wordpress getent hosts mariadb

docker compose exec mariadb sh -c 'ls -la /run/secrets/'

docker compose config --volumes
