# Build CAS Server

## Configuration

Please modify following files before build docker image or run docker containers.

1. `docker/config.yml`: configuration for ruby-cas-server.
2. `docker/.env`: environments for docker compose.
3. `docker/cas-mysql.env`: environments for cas-mysql container.
4. `docker/cas-dev.env`: environments for cas-dev container.
5. `docker/cas-web.env`: environments for cas-web container.

Please rebuild docker image after `docker/config.yml` modified.

Please increment docker image version tag in `docker/.env` before you build docker image.

## Docker Compose

### dev

``` shell
docker compose --env-file docker/.env config
docker compose --env-file docker/.env build cas-dev
docker compose --env-file docker/.env up cas-dev
docker compose --env-file docker/.env start cas-dev
docker compose --env-file docker/.env exec cas-dev bundle exec irb
docker compose --env-file docker/.env exec cas-dev sh
open http://127.0.0.1:4000
```

### web

``` shell
docker compose --env-file docker/.env config
docker compose --env-file docker/.env build cas-web
docker compose --env-file docker/.env up --no-start cas-web
docker compose --env-file docker/.env up -d --no-recreate cas-web
docker compose --env-file docker/.env exec cas-web bundle exec irb
docker compose --env-file docker/.env exec cas-web sh
open http://127.0.0.1:6000
```

### mysql

Database will create automatically after cas-mysql container run up, otherwise run manually.

``` shell
mysqladmin -h cas-mysql -u root -p create casserver
```

### Network Status

Check network via one of following.

``` shell
netstat -anvp tcp | awk 'NR<3 || /LISTEN/'
sudo lsof -PiTCP -sTCP:LISTEN
sudo lsof -Pn -i4
```
