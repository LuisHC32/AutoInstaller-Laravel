# Readme.md LaravelOneCommand

### ¿Que hace LaravelOneCommand?
Se configura un contenedor los servicios de PHP, MySQL y Nginx con docker-compose.yml. Dentro de PHP se encuentra un Dockerfile que se encarga de instalar las dependencias del sistema a utilizar, extensiones de PHP necesarias y descarga la ultima version de composer para posteriormente establecer el directorio de trabajo y ejecutar el script init.sh que se encarga de crear el proyecto Laravel, dentro de este init.sh, verifica si ya existe el proyecto Laravel comprobando si existe un archivo 'artisan', en caso de que no exista, crea el proyecto. Posteriormente configura el .env del proyecto, tomando los datos del .env de la raiz y reemplaza la configuracion con sed y posteriormente las descomenta, para finalizar establece los permisos necesarios y ejecuta php-fpm.
Para el caso del servicio de MySQL, este se configuro en el puerto default (3306).
Se utiliza Nginx y su respectivo default.conf para renderizar la aplicacion web.

1. Configura tu .env.
2. ```docker compose up``` Para crear el container con los servicios requeridos. 
3. Espera y verifica que se haya creado el proyecto.
4. ```docker compose exec php php artisan migrate``` Para migrar la base de datos. (Si es necesario).

### Extras:
* Replicas
-Si se desea escalar el servicio de php, se debe modificar el docker-compose.yml y agregar ```replicas: x``` y ejecutar ```docker compose up --scale php=X```
* Resources:
  Limits/Reservations: Minimo y maximo de recursos en cpu (cpus) y RAM (memory)

Ejemplo:
```
    deploy:
      replicas: 3 
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```