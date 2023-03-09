set :stage, "production"

set :deploy_to, "/home/deployer/rubycas"

# Deployer's sudo password, default value is nil
# set :sudo_password, "deployer_password"

# Folder name under "./compose_projects", default value is nil
set :docker_compose_project, "cas_demo"

# Main service name in docker-compose.yml file, default value is nil
set :docker_compose_service, "cas-web"

# Docker compose command in deploy host, default value is 'docker compose'
set :docker_compose_command, 'docker compose'

# Use private docker registry or docker.io registry by REGISTRY_URI, default value is false
set :use_docker_registry, false

# Service configuration (For build docker image)
server "127.0.0.1",
  # user: "deployer",
  # password: "deployer_password",
  roles: %w{builder},
  primary: true

# Service configuration (For deploy docker image)
server "127.0.0.1",
  # user: "deployer",
  # password: "deployer_password",
  roles: %w{app},
  primary: true
