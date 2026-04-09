FROM php:8.2-fpm-alpine

# Instala las dependencias del sistema
RUN apk add --no-cache \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    oniguruma-dev

# Instala las extensiones de PHP
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Descarga la última versión de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copia el script init.sh
COPY php/init.sh /usr/local/bin/init.sh
RUN sed -i 's/\r$//' /usr/local/bin/init.sh && \
    chmod +x /usr/local/bin/init.sh

# Establece el directorio de trabajo
WORKDIR /var/www/html

# Ejecuta el script init.sh (crea Laravel + configura .env + inicia php-fpm)
ENTRYPOINT ["init.sh"]
