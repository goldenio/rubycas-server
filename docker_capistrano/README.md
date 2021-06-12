# Docker deploy via Capistrano

## Workflow

### First Time Deploy

Add project files under `./compose_projects/xxx`, then deploy project.

NOTE: If `REGISTRY_URI` is set in `docker/.env`, `use_docker_registry` needs to be `true` in `config/deploy/production.rb`.

``` shell
cd docker_capistrano
bundle install
bundle exec cap production deploy:check
bundle exec cap production docker:compose:upload_files
bundle exec cap production deploy:register_image
bundle exec cap production deploy:create_network
```

Go to create network and run database service of authenticator before execute real deploy.

``` shell
cd docker_capistrano
bundle exec cap production deploy:docker_image
```

### Deploy New Image After Code Changed

Modify image tag in `./compose_projects/xxx/docker/.env` first.

``` shell
cd docker_capistrano
bundle exec cap production docker:compose:upload_files
bundle exec cap production deploy:register_image
bundle exec cap production deploy:docker_image
```

### Restart Current Service Without Code Changes

``` shell
cd docker_capistrano
bundle exec cap production docker:compose:restart_service
```

### Recreate Current Service Without Code Changes

``` shell
cd docker_capistrano
bundle exec cap production docker:compose:up_service
```

## All Docker Tasks

The work flow tasks:

``` shell
cd docker_capistrano
bundle exec cap production deploy:register_image
bundle exec cap production deploy:create_network
bundle exec cap production deploy:docker_image
```

The compose tasks:

``` shell
cd docker_capistrano
bundle exec cap production docker:compose:upload_files
bundle exec cap production docker:compose:download_files
bundle exec cap production docker:compose:copy_build_files
bundle exec cap production docker:compose:copy_volume_files
bundle exec cap production docker:compose:config
bundle exec cap production docker:compose:build_image
bundle exec cap production docker:compose:create_service
bundle exec cap production docker:compose:remove_service
bundle exec cap production docker:compose:start_service
bundle exec cap production docker:compose:stop_service
bundle exec cap production docker:compose:restart_service
bundle exec cap production docker:compose:up_service
bundle exec cap production docker:compose:up_no_recreate_service
```

NOTE: It might only work if `current` folder is present in remote when it executes alone.

The docker tasks:

``` shell
cd docker_capistrano
bundle exec cap production docker:push_image
bundle exec cap production docker:pull_image
```
