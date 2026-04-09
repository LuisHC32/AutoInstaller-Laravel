#!/bin/sh
set -e

# Verifica si Laravel ya está instalado (existe el archivo artisan)
if [ ! -f /var/www/html/artisan ]; then
    echo "Laravel no detectado. Creando proyecto..."

    # Crea el proyecto Laravel en un directorio temporal
    composer create-project --prefer-dist laravel/laravel /tmp/laravel-temp

    # Copia todo al volumen montado
    cp -a /tmp/laravel-temp/. /var/www/html/

    # Limpia el directorio temporal
    rm -rf /tmp/laravel-temp

    echo "Proyecto Laravel creado exitosamente!"
else
    echo "Laravel ya existe. Saltando instalacion."
fi

# Actualiza .env con los valores de la base de datos (pasados desde el .env raíz a través de docker-compose)
if [ -f /var/www/html/.env ]; then
    echo "Configurando .env con variables de base de datos..."

    # Reemplaza la configuración de la base de datos usando sed
    sed -i "s|^DB_CONNECTION=.*|DB_CONNECTION=${DB_CONNECTION}|" /var/www/html/.env
    sed -i "s|^DB_HOST=.*|DB_HOST=${DB_HOST}|" /var/www/html/.env
    sed -i "s|^DB_PORT=.*|DB_PORT=${DB_PORT}|" /var/www/html/.env
    sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${DB_DATABASE}|" /var/www/html/.env
    sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${DB_USERNAME}|" /var/www/html/.env
    sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|" /var/www/html/.env

    # Descomenta las líneas de la base de datos si están comentadas
    sed -i "s|^# DB_HOST=.*|DB_HOST=${DB_HOST}|" /var/www/html/.env
    sed -i "s|^# DB_PORT=.*|DB_PORT=${DB_PORT}|" /var/www/html/.env
    sed -i "s|^# DB_DATABASE=.*|DB_DATABASE=${DB_DATABASE}|" /var/www/html/.env
    sed -i "s|^# DB_USERNAME=.*|DB_USERNAME=${DB_USERNAME}|" /var/www/html/.env
    sed -i "s|^# DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|" /var/www/html/.env
fi

# Establece los permisos adecuados
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

exec php-fpm
