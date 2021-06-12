namespace :load do
  task :defaults do
    invoke 'docker:compose:defaults'
  end
end

namespace :docker do

  def ask_to_upload(files, source_path)
    files.each do |file|
      next if file.nil?
      next unless file.strip.length.positive?
      if File.exist? source_path.join(file)
        ask(:upload_file, 'Y', echo: true, prompt: "Local file '#{file}' existed, upload now? [Y/n]")
      else
        set(:upload_file, nil)
      end
      if fetch(:upload_file).to_s == 'Y'
        source_file = source_path.join(file).to_s
        target_file = shared_path.join(file).to_s
        if test(:ls, target_file)
          ask(:upload_file, 'Y', echo: true, prompt: "Remote file '#{file}' existed, overwrite? [Y/n]")
        end
        if fetch(:upload_file).to_s == 'Y'
          upload! source_file, target_file
        end
      end
      set(:upload_file, nil)
    end
  end

  def ask_to_download(files, target_path)
    files.each do |file|
      next if file.nil?
      next unless file.strip.length.positive?
      if File.exist? target_path.join(file)
        ask(:download_file, 'Y', echo: true, prompt: "Local file '#{file}' existed, still download? [Y/n]")
      else
        set(:download_file, 'Y')
      end
      if fetch(:download_file).to_s == 'Y'
        FileUtils.mkdir_p target_path.join(file).dirname
        source_file = shared_path.join(file).to_s
        target_file = target_path.join(file).to_s
        if test(:ls, source_file)
          download! source_file, target_file
        else
          warn "Remote file '#{file}' is not found!"
        end
      end
      set(:download_file, nil)
    end
  end

  def copy_files_from_shared_to_release(files)
    files.each do |file|
      source_file = shared_path.join(file).to_s
      target_file = release_path.join(file).to_s
      if test(:ls, target_file)
        execute :rm, target_file
      end
      execute :cp, source_file, target_file
      if file =~ /\.log\z/
        execute :chmod, '666', target_file
      end
    end
  end

  namespace :compose do
    task :defaults do
      # Required files while build docker image
      set :docker_compose_build_files, []
      # Required files while run docker container
      set :docker_compose_volume_files, []
      # Folder name under "./compose_projects"
      set :docker_compose_project, nil
      # Main service name in docker-compose.yml file
      set :docker_compose_service, nil
      # Use private docker registry
      set :use_docker_registry, false
    end

    desc 'Check directories of files to be uploaded exist in shared'
    task :make_uploaded_directories do
      if any? :docker_compose_build_files
        on roles([:builder]) do
          files = fetch(:docker_compose_build_files)
          pathes = map_dirnames(join_paths(shared_path, files))
          execute :mkdir, '-p', pathes
        end
      end
      if any? :docker_compose_volume_files
        on roles([:app, :builder]) do
          files = fetch(:docker_compose_volume_files)
          pathes = map_dirnames(join_paths(shared_path, files))
          execute :mkdir, '-p', pathes
        end
      end
    end
    after 'deploy:check:directories', 'docker:compose:make_uploaded_directories'

    desc 'upload files'
    task :upload_files do
      next puts 'Please set :docker_compose_project first!' unless any? :docker_compose_project
      source_path = Pathname.new(File.join(Dir.pwd, 'compose_projects', fetch(:docker_compose_project, '')))
      next unless File.exist? source_path
      on roles([:app, :builder]) do
        files = fetch(:linked_files)
        ask_to_upload(files, source_path)
      end
      on roles([:builder]) do
        files = fetch(:docker_compose_build_files)
        ask_to_upload(files, source_path)
      end
      on roles([:app, :builder]) do
        files = fetch(:docker_compose_volume_files)
        ask_to_upload(files, source_path)
      end
    end

    desc 'download files'
    task :download_files do
      next puts 'Please set :docker_compose_project first!' unless any? :docker_compose_project
      target_path = Pathname.new(File.join(Dir.pwd, 'compose_projects', fetch(:docker_compose_project, '')))
      FileUtils.mkdir_p target_path
      next unless File.exist? target_path
      on roles([:app, :builder]) do
        files = fetch(:linked_files)
        ask_to_download(files, target_path)
      end
      on roles([:builder]) do
        files = fetch(:docker_compose_build_files)
        ask_to_download(files, target_path)
      end
      on roles([:app, :builder]) do
        files = fetch(:docker_compose_volume_files)
        ask_to_download(files, target_path)
      end
    end

    desc 'copy required files for build image'
    task :copy_build_files do
      next unless any? :docker_compose_build_files
      on roles([:builder]) do
        files = fetch(:docker_compose_build_files)
        copy_files_from_shared_to_release(files)
      end
    end

    desc 'copy required files for run container'
    task :copy_volume_files do
      next unless any? :docker_compose_volume_files
      on roles([:app, :builder]) do
        files = fetch(:docker_compose_volume_files)
        copy_files_from_shared_to_release(files)
      end
    end

    desc 'validate config file'
    task :config do
      next puts 'Please set :docker_compose_service first!' unless any? :docker_compose_service
      service_name = fetch(:docker_compose_service)
      next unless service_name.strip.length.positive?
      on roles([:app, :builder]) do
        within release_path do
          with_sudo_password do
            execute(:sudo, 'docker-compose',
              '--env-file docker/.env',
              'config')
          end
        end
      end
    end

    desc 'build image'
    task :build_image do
      next puts 'Please set :docker_compose_service first!' unless any? :docker_compose_service
      service_name = fetch(:docker_compose_service)
      next unless service_name.strip.length.positive?
      on roles([:builder]) do
        within release_path do
          with_sudo_password do
            execute(:sudo, 'docker-compose',
              '--env-file docker/.env',
              'build', service_name)
          end
        end
      end
    end
    before :build_image, :copy_build_files

    desc 'create service(s)'
    task :create_service do
      next puts 'Please set :docker_compose_service first!' unless any? :docker_compose_service
      service_name = fetch(:docker_compose_service)
      next unless service_name.strip.length.positive?
      on roles([:app]) do
        within release_path do
          with_sudo_password do
            execute(:sudo, 'docker-compose',
              '--env-file docker/.env',
              'up', '--no-start', service_name)
          end
        end
      end
    end

    desc 'remove service(s)'
    task :remove_service do
      next puts 'Please set :docker_compose_service first!' unless any? :docker_compose_service
      service_name = fetch(:docker_compose_service)
      next unless service_name.strip.length.positive?
      on roles([:app]) do
        within release_path do
          with_sudo_password do
            execute(:sudo, 'docker-compose',
              '--env-file docker/.env',
              'rm', '-f', service_name)
          end
        end
      end
    end

    desc 'start service(s)'
    task :start_service do
      next puts 'Please set :docker_compose_service first!' unless any? :docker_compose_service
      service_name = fetch(:docker_compose_service)
      next unless service_name.strip.length.positive?
      on roles([:app]) do
        within release_path do
          with_sudo_password do
            execute(:sudo, 'docker-compose',
              '--env-file docker/.env',
              'start', service_name)
          end
        end
      end
    end

    desc 'stop service(s)'
    task :stop_service do
      next puts 'Please set :docker_compose_service first!' unless any? :docker_compose_service
      service_name = fetch(:docker_compose_service)
      next unless service_name.strip.length.positive?
      on roles([:app]) do
        within release_path do
          with_sudo_password do
            execute(:sudo, 'docker-compose',
              '--env-file docker/.env',
              'stop', service_name)
          end
        end
      end
    end

    desc 'restart service(s)'
    task :restart_service do
      next puts 'Please set :docker_compose_service first!' unless any? :docker_compose_service
      service_name = fetch(:docker_compose_service)
      next unless service_name.strip.length.positive?
      on roles([:app]) do
        within release_path do
          with_sudo_password do
            execute(:sudo, 'docker-compose',
              '--env-file docker/.env',
              'restart', service_name)
          end
        end
      end
    end

    desc 'recreate and start service(s)'
    task :up_service do
      next puts 'Please set :docker_compose_service first!' unless any? :docker_compose_service
      service_name = fetch(:docker_compose_service)
      next unless service_name.strip.length.positive?
      on roles([:app]) do
        within release_path do
          with_sudo_password do
            execute(:sudo, 'docker-compose',
              '--env-file docker/.env',
              'up', '-d', service_name)
          end
        end
      end
    end

    desc 'create and start service(s)'
    task :up_no_recreate_service do
      next puts 'Please set :docker_compose_service first!' unless any? :docker_compose_service
      service_name = fetch(:docker_compose_service)
      next unless service_name.strip.length.positive?
      on roles([:app]) do
        within release_path do
          with_sudo_password do
            execute(:sudo, 'docker-compose',
              '--env-file docker/.env',
              'up', '-d', '--no-recreate', service_name)
          end
        end
      end
    end

    desc 'push image of service(s)'
    task :push_image do
      next puts 'Skip push image to private docker registry!' unless fetch(:use_docker_registry)
      next puts 'Please set :docker_compose_service first!' unless any? :docker_compose_service
      service_name = fetch(:docker_compose_service)
      next unless service_name.strip.length.positive?
      on roles([:builder]) do
        within release_path do
          with_sudo_password do
            execute(:sudo, 'docker-compose',
              '--env-file docker/.env',
              'push', service_name)
          end
        end
      end
    end

    desc 'pull image of service(s)'
    task :pull_image do
      next puts 'Skip pull image from private docker registry!' unless fetch(:use_docker_registry)
      next puts 'Please set :docker_compose_service first!' unless any? :docker_compose_service
      service_name = fetch(:docker_compose_service)
      next unless service_name.strip.length.positive?
      on roles([:app]) do
        within release_path do
          with_sudo_password do
            execute(:sudo, 'docker-compose',
              '--env-file docker/.env',
              'pull', service_name)
          end
        end
      end
    end
  end
end

# Deploy flow with docker compose tasks
namespace :deploy do
  desc 'Build and register a new docker image'
  task :register_image do
    set(:deploying, true)
    %w{
      deploy:starting
      deploy:started
      deploy:updating
      docker:compose:copy_volume_files
      docker:compose:config
      docker:compose:build_image
      docker:compose:push_image
      deploy:updated
    }.each { |task| invoke task }
  end

  desc 'Create network'
  task :create_network do
    set(:deploying, true)
    %w{
      deploy:starting
      deploy:started
      deploy:updating
      docker:compose:copy_volume_files
      docker:compose:config
      docker:compose:pull_image
      docker:compose:create_service
      docker:compose:up_service
      deploy:updated
    }.each { |task| invoke task }
  end

  desc 'Deploy a docker image'
  task :docker_image do
    set(:deploying, true)
    %w{
      deploy:starting
      deploy:started
      deploy:updating
      docker:compose:copy_volume_files
      docker:compose:config
      docker:compose:pull_image
      deploy:updated
      deploy:publishing
      docker:compose:stop_service
      docker:compose:remove_service
      docker:compose:up_service
      deploy:published
      deploy:finishing
      deploy:finished
    }.each { |task| invoke task }
  end
end
