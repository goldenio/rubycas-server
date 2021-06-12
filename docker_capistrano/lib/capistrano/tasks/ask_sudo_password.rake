namespace :load do
  task :defaults do
    invoke 'ask_sudo_password:defaults'
  end
end

namespace :ask_sudo_password do
  task :defaults do
    # Deployer's sudo password
    set :sudo_password, nil
  end

  # https://stackoverflow.com/questions/21659637/how-to-fix-sudo-no-tty-present-and-no-askpass-program-specified-error
  SSHKit.config.command_map[:sudo] = 'echo $SUDO_PASSWORD | /usr/bin/sudo -S'

  def with_sudo_password(&block)
    if fetch(:sudo_password, '').to_s.empty?
      ask(:sudo_password, nil, echo: false, prompt: 'Please enter sudo password')
    end
    return if fetch(:sudo_password, '').to_s.empty?

    with sudo_password: fetch(:sudo_password) do
      yield
    end
  end
end
