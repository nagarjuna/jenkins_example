require 'mina/multistage'
require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/puma' if fetch(:stage) == 'web'
# load '/lib/tasks/mina/resque/tasks.rake' if fetch(:stage) == 'bg'

set :stages, %w(web bg)
set :default_stage, 'web'
# require 'mina/rbenv'  # for rbenv support. (https://rbenv.org)
require 'mina/rvm'    # for rvm support. (https://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :application_name, 'jenkins_example'
set :application_env, 'development'
set :rails_env, 'development'
set :verbose, false
set :repository, 'https://github.com/nagarjuna/jenkins_example.git'
set :branch, 'master'
# set :domain, 'foobar.com'
# set :deploy_to, '/var/www/foobar.com'
# set :repository, 'git://...'
# set :branch, 'master'

# Optional settings:
#   set :user, 'foobar'          # Username in the server to SSH to.
#   set :port, '30000'           # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# Shared dirs and files will be symlinked into the app-folder by the 'deploy:link_shared_paths' step.
# Some plugins already add folders to shared_dirs like `mina/rails` add `public/assets`, `vendor/bundle` and many more
# run `mina -d` to see all folders and files already included in `shared_dirs` and `shared_files`
# set :shared_dirs, fetch(:shared_dirs, []).push('public/assets')
# set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/secrets.yml')
set :shared_dirs, fetch(:shared_dirs, []).push('log', 'tmp/pids', 'tmp/sockets', 'public/uploads')
set :shared_files, fetch(:shared_files, []).push('config/master.key', 'config/puma.rb', 'config/database.yml')

# Puma server settings
set :puma_config,    -> { "#{fetch(:shared_path)}/config/puma.rb" }
# set :puma_cmd,       -> { "#{fetch(:bundle_prefix)} puma" }
# set :pumactl_cmd,    -> { "#{fetch(:bundle_prefix)} pumactl" }
# set :pumactl_socket, -> { "#{fetch(:shared_path)}/tmp/sockets/pumactl.sock" }

# This task is the environment that is loaded for all remote run commands, such as
# `mina deploy` or `mina rake`.
task :remote_environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  invoke :'rvm:use', 'ruby-2.5.3@default'
end

# Put any custom commands you need to run at setup
# All paths in `shared_dirs` and `shared_paths` will be created on their own.
task :setup do
  # command %{rbenv install 2.3.0 --skip-existing}
  command %[touch "#{fetch(:shared_path)}/config/master.key"]
end

task :restart_nginx do
  command 'sudo service nginx restart'
end

task :copy_credentials_file do
  command %[
      cp ./config/#{fetch(:application_env)}.credentials.yml.enc ./config/credentials.yml.enc

      if [ ! -e "#{fetch(:shared_path)}/config/puma.rb" ]; then
        cp ./config/puma.conf #{fetch(:shared_path)}/config/puma.rb
      fi
      if [ ! -e "#{fetch(:shared_path)}/config/database.yml" ]; then
        cp ./config/database.yml #{fetch(:shared_path)}/config/database.yml
      fi
    ]
end


desc "Deploys the current version to the server."
task :deploy do
  # uncomment this line to make sure you pushed your local branch to the remote origin
  # invoke :'git:ensure_pushed'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    comment "Deploying #{fetch(:application_name)} to #{fetch(:domain)}:#{fetch(:deploy_to)}"
    invoke :'git:clone'
    # invoke :'copy_credentials_file' 
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    # invoke :'rails:db_migrate'
    # command %[yarn install --check-files]
    # command %[WEBPACKER_PRECOMPILE=false ]
    # invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'
    # on :launch do
    #   if fetch(:stage) == 'web'
    #     invoke :'puma:phased_restart'
    #   elsif fetch(:stage) == 'bg'
    #     invoke :'resque:stop'
    #     invoke :'resque:start'
    #   end
    # end
  end

  # you can use `run :local` to run tasks on local machine before of after the deploy scripts
  # run(:local){ say 'done' }
end

set :resque_pid_path, -> { File.join(fetch(:shared_path), 'tmp', 'pids') }
set :workers, { "*" => 5 }

namespace :resque do
  desc "Start Resque workers"
  task :start do
    worker_id = 1
    fetch(:workers).each do |queue, number_of_workers|
      comment "Starting #{number_of_workers} worker(s) with QUEUE: #{queue}"
      number_of_workers.times do
        pid = "#{fetch(:resque_pid_path)}/resque_work_#{worker_id}.pid"
        in_path(fetch(:current_path)) do
          command %[RACK_ENV=#{fetch(:rails_env)} RAILS_ENV=#{fetch(:rails_env)} QUEUE=#{queue} PIDFILE=#{pid} BACKGROUND=yes VERBOSE=0  INTERVAL=5 bundle exec rake resque:work log/resque.log 2>> log/resque.log ]
        end
        worker_id += 1
      end
    end
  end

  desc "See current worker status"
  task :status do
    command %[
      if [ -e "#{fetch(:resque_pid_path)}/resque_work_1.pid" ]; then
        for pid_file in #{fetch(:resque_pid_path)}/resque_work*.pid; do
          echo "$(ps -f -p $(cat $pid_file) | sed -n 2p)"
        done
      else
        echo "No resque workers running";
      fi
    ]
  end

  desc "Quit running Resque workers"
  task :stop do
    command %[
      if [ -e "#{fetch(:resque_pid_path)}/resque_work_1.pid" ]; then
        for pid_file in #{fetch(:resque_pid_path)}/resque_work*.pid; do
          worker_pid=$(cat $pid_file)
          if kill -0 $worker_pid > /dev/null 2>&1; then
            kill -s QUIT $worker_pid && rm $pid_file
          else
            echo "Process $worker_pid from $pid_file is not running, cleaning up stale PID file";
            rm $pid_file
          fi
        done
      else
        echo "No resque PID files found";
      fi
    ]
  end
end

# namespace :puma do
#   desc "Start the application"
#   task :start do
#     command 'echo "-----> Start Puma"'
#     command "cd #{fetch(:current_path)} && RAILS_ENV=#{fetch(:rails_env)} && bundle exec puma -C #{fetch(:deploy_to)}/shared/config/puma.rb start"
#   end

#   desc "Stop the application"
#   task :stop do
#     command 'echo "-----> Stop Puma"'
#     command "cd #{fetch(:current_path)} && RAILS_ENV=#{fetch(:rails_env)} && bundle exec pumactl -F #{fetch(:deploy_to)}/shared/config/puma.rb stop"
#   end
# end

# For help in making your deploy script, see the Mina documentation:
#
#  - https://github.com/mina-deploy/mina/tree/master/docs
