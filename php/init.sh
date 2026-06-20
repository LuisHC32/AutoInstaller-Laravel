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

    if [ ! -f /var/www/html/vendor/autoload.php ]; then
        echo "Instalando dependencias de Composer..."
        composer install --no-interaction --prefer-dist --optimize-autoloader
    fi

    if [ ! -f /var/www/html/.env ] && [ -f /var/www/html/.env.example ]; then
        echo "Creando .env desde .env.example..."
        cp /var/www/html/.env.example /var/www/html/.env
    fi
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

# Genera APP_KEY si aún no existe
if [ -f /var/www/html/.env ] && ! grep -q '^APP_KEY=base64:' /var/www/html/.env; then
    echo "Generando APP_KEY..."
    php artisan key:generate --force
fi

# Crea el enlace simbólico de storage si no existe
if [ ! -L /var/www/html/public/storage ]; then
    php artisan storage:link 2>/dev/null || true
fi

# Compila assets de Vite si aún no existen
if [ -f /var/www/html/package.json ] && [ ! -f /var/www/html/public/build/manifest.json ]; then
    echo "Compilando assets de frontend..."
    if [ -f /var/www/html/package-lock.json ]; then
        npm ci --no-audit --no-fund
    else
        npm install --no-audit --no-fund
    fi
    npm run build
fi

# Espera a MySQL y ejecuta migraciones pendientes
if [ -f /var/www/html/artisan ] && [ -f /var/www/html/vendor/autoload.php ]; then
    echo "Esperando a que MySQL esté disponible..."
    i=0
    while [ "$i" -lt 30 ]; do
        if php -r "new PDO('mysql:host=${DB_HOST};port=${DB_PORT};dbname=${DB_DATABASE}', '${DB_USERNAME}', '${DB_PASSWORD}');" 2>/dev/null; then
            break
        fi
        i=$((i + 1))
        sleep 2
    done

    if [ "$i" -lt 30 ]; then
        echo "Ejecutando migraciones..."
        php artisan migrate --force --no-interaction
    else
        echo "Advertencia: MySQL no disponible. Migraciones omitidas."
    fi
fi

# Establece los permisos adecuados
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

exec php-fpm
