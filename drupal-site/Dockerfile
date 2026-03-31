FROM drupal:10-php8.2-fpm-alpine

# Install additional PHP extensions if needed
RUN docker-php-ext-install pdo pdo_pgsql

WORKDIR /var/www/html

# Copy Drupal files
COPY web /var/www/html/web
COPY config /var/www/html/config

# Install dependencies
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer install --no-dev --optimize-autoloader

EXPOSE 80
