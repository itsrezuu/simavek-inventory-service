# Sesuaikan base image dengan teknologi aplikasimu
# Contoh untuk Laravel/PHP:
FROM php:8.2-fpm-alpine

WORKDIR /app

RUN apk add --no-cache postgresql-dev \
    && docker-php-ext-install pdo pdo_pgsql

COPY . .

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer install --no-dev --optimize-autoloader

EXPOSE 8000

CMD ["php-fpm"]