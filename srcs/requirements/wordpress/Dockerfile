# 1. Install the SOFTWARE WordPress needs
#        ↓
#    PHP
#    PHP-FPM
#    PHP-MySQL
#    curl
#    WP-CLI
#        ↓
# 2. Put WordPress files in the image
#        ↓
# 3. Copy script
#        ↓
# 4. Give script execution permission
#        ↓
# 5. ENTRYPOINT → run script at container

FROM debian:12

# Install PHP-FPM, PHP-MySQL, and tools needed by WordPress
RUN apt-get update && \
    apt-get install -y \
        php8.2-fpm \
        php8.2-mysql \
        curl \
        mariadb-client \
        ca-certificates

# Install WP-CLI
RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        -o /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# Copy the WordPress startup script
COPY tools/script.sh /usr/local/bin/script.sh

# Give the script execution permission
RUN chmod +x /usr/local/bin/script.sh

# PHP-FPM listens on port 9000
EXPOSE 9000

WORKDIR /var/www/html

# Run the WordPress startup script when the container starts
ENTRYPOINT ["/usr/local/bin/script.sh"]
# CMD [ "bash" ]