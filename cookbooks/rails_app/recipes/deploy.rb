#
# Cookbook Name:: rails_app
# Recipe:: setup
#
# Copyright 2010, VersaPay
#
# All rights reserved - Do Not Redistribute
#


# Fetch the application this recipe is deploying
# node.run_state[:app_name] is setup by the default recipe
app_name = node.run_state[:app_name]

# We can't use these two little shiny variable because of a bad bug.
# See my_app = node.rails_app
app = node.send(app_name)
rails_defaut = node.rails_app

node.rails_app.user = node[:deploy_user][:user]
node.rails_app.group = node[:deploy_user][:user]
# Install packages
packages = node[app_name].packages.to_hash.merge(node.rails_app.packages.to_hash)

packages.each do |pkg, ver|
  package pkg do
    action :install
    version ver if ver && !ver.empty?
  end
end

# Install gems
gems = node[app_name].gems.to_hash.merge(node.rails_app.gems.to_hash)
gems.each do |gem,ver|
  execute "#{node[:languages][:ruby][:gem_bin]} install #{gem} #{"-v #{ver}" if ver}" do
    user "root"
  end
  # gem_package gem do
  #   action :install
  #   version ver if ver && !ver.empty?
  # end
end

# Add the current RAILS_ENV to all shells
template "/etc/profile.d/rails_env.sh" do
  source "rails_env.sh.erb"
  owner "root"
  group "root"
  mode "0755"
  variables :rails_env => node.rails_app.environment
end

# Create directories to deploy the application
app_dir = "#{node.rails_app.deploy_dir}/#{app_name}"
shared_dir = app_dir + '/shared'

shared_dirs = node.rails_app.shared_dirs.map { |d| "#{shared_dir}/#{d}" }
shared_dirs.each do |dir|
  directory dir do
    owner node.rails_app.user
    group node.rails_app.group
    mode '0755'
    recursive true
  end
end

# Logrotate
logrotate_app app_name do
  paths shared_dir + '/log/*.log'
  rotate 4
end

# Setup deploy-ssh-wrapper
# Note: This is a mad workaround made in opscode. The resource deploy_revision
# will use it to git clone the app
if node.send(app_name).attribute?(:deploy_key)
  deploy_key_path = shared_dir + '/deploy_key'

  ruby_block "write_key" do
    block do
      File.open(deploy_key_path, "w") do |f|
        f.print(app["deploy_key"])
      end
    end
    # always overwrite the deploy_key with the one from the databag
  end

  # Make the deploy_key readable by owner only
  file deploy_key_path do
    owner node.rails_app.user
    group node.rails_app.group
    mode '0600'
  end

  template "#{shared_dir}/deploy-ssh-wrapper" do
    source "deploy-ssh-wrapper.erb"
    owner node.rails_app.user
    group node.rails_app.group
    mode "0755"
    variables(:id => app["id"], :deploy_key_path => deploy_key_path)
    not_if { File.exists?("#{shared_dir}/deploy-ssh-wrapper") }
  end
end

# iptables for ssh tunnel
if node.roles.include?(app_name) && node.roles.include?('database_master')
  database_master = node
else
  database_master = search(:node, "roles:#{app_name} AND chef_environment:#{node.chef_environment} AND roles:database_master", nil, 0, 1)[0][0]
end

if database_master
  iptables_rule "output_db_master_#{database_master.hostname}" do
    dport 22
    chain 'OUTPUT'
    destination database_master.ipaddress
    comment "mysql ssh tunnel to #{database_master.hostname}"
  end
end

additional_databases = search(:node, "roles:#{app_name} AND chef_environment:#{node.chef_environment} AND roles:additional_database")
if node.roles.include?(app_name) && node.roles.include?("additional_database")
  additional_databases << node
end
extra_dbs = []

additional_databases.each do |db|
  iptables_rule "output_db_master_#{db.hostname}" do
    dport 22
    chain 'OUTPUT'
    destination db.ipaddress
    comment "mysql ssh tunnel to #{db.hostname}"
  end
end

errbit_server = search(:node, "role:errbit AND role:app_server", nil, 0, 1)[0][0]
if errbit_server
  iptables_rule "output_errbit_server_#{errbit_server.hostname}" do
    dport 443
    chain 'OUTPUT'
    destination errbit_server.ipaddress
    comment "Https connection the errbit for reporting errors"
  end
end

# Let's deploy
deploy_revision app_name do
  action (node[:force_deploy] ? :force_deploy : :deploy)

  revision node.send(app_name).environments.send(node.rails_app.environment).branch
  repository node.send(app_name).repository

  user node.rails_app.user
  group node.rails_app.group

  deploy_to app_dir

  environment 'RAILS_ENV' => node.rails_app.environment, 'RACK_ENV' => node.rails_app.environment

  rake_command = node.send(app_name).gems.keys.include?("bundler") ? "bundle exec rake" : "rake"

  ssh_wrapper "#{shared_dir}/deploy-ssh-wrapper" if node.send(app_name).attribute?(:deploy_key)

  if node.roles.include?(node.rails_app.run_migration_role) && !node[app_name]['skip_migrations']
    migrate true
    migration_command "#{rake_command} db:migrate"
  else
    migrate false
  end

  symlinks("system" => "public/system", "pids" => "tmp/pids", "log" => "log", "files" => "files")

  restart_command "touch tmp/restart.txt"

  # Please keep empty so that apps without a config/database.yml file will still work
  symlink_before_migrate({})


  before_migrate do
    # Make shared_path visible in 'link' blocks
    shared_path = @new_resource.shared_path
    # Setup database.yml
    # if node.roles.include?(app_name) && node.roles.include?('database_master')
    #   database_master = node
    # else
    #   database_master = search(:node, "roles:#{app_name} AND chef_environment:#{node.chef_environment} AND roles:database_master", nil, 0, 1)[0][0]
    # end

    if node.roles.include?(app_name) && node.roles.include?('mongo_database_master')
      mongo_database_master = node
    else
      mongo_database_master = search(:node, "roles:#{app_name} AND chef_environment:#{node.chef_environment} AND roles:mongo_database_master", nil, 0, 1)[0][0]
    end

    password = database_master.mysql.users[app_name][:password]

    # If a database master exists
    if database_master
      # If we're going to tunnel our db connection
      if node[app_name][:environments][node.rails_app.environment][:secure_db_connection]
        db_host = '127.0.0.1'
        db_port = 4406

        # Setup an ssh tunnel
        ssh_tunnel "#{app_name}-#{node.rails_app.environment}-db-tunnel" do
          local_port 4406
          host database_master.ipaddress
          host_port 3306
        end

        additional_databases.each do |db|
          env = node.rails_app.environment
          name = db[app_name][:database_name]
          additional_db_port = 4407 + additional_databases.index(db)
          extra_dbs << { :env => "#{name}_#{env}", :host => '127.0.0.1', :port => additional_db_port, :database => "#{app_name}_#{name}_#{env}", :username => app_name, :password => db.mysql.users[app_name][:password] }

          # Setup an ssh tunnel
          ssh_tunnel "#{app_name}-#{name}-#{node.rails_app.environment}-db-tunnel" do
            local_port additional_db_port
            host db.ipaddress
            host_port 3306
          end
        end
      else
        db_host = database_master.ipaddress
        db_port = 3306

        additional_databases.each do |db|
          env = node.rails_app.environment
          name = db[app_name][:database_name]
          extra_dbs << { :env => "#{name}_#{env}", :host => db.ipaddress, :port => 3306, :database => "#{app_name}_#{name}_#{env}", :username => app_name, :password => db.mysql.users[app_name][:password] }
        end
      end

      template "#{shared_path}/database.yml" do
        source "database.yml.erb"
        owner app["owner"]
        group app["group"]
        mode "644"
        variables(
          :env => node.rails_app.environment,
          :host => db_host,
          :port => db_port,
          :database => "#{app_name}_#{node.rails_app.environment}",
          :username => app_name,
          :password => password,
          :extra_dbs => extra_dbs
        )
      end

      # Delete and symlink our new db config file
      db_config = File.join(release_path, 'config', 'database.yml')
      File.delete(db_config) if File.exists?(db_config)

      link db_config do
        to "#{shared_path}/database.yml"
      end
    elsif mongo_database_master
      #If we're going to tunnel our db connection
      if node[app_name][:environments][node.rails_app.environment][:secure_db_connection]
        db_host = '127.0.0.1'
        db_port = 4406

        # Setup an ssh tunnel
        ssh_tunnel "#{app_name}-#{node.rails_app.environment}-db-tunnel" do
          local_port 4406
          host mongo_database_master.ipaddress
          host_port mongo_database_master[:mongodb][:port]
        end
      else
        db_host = mongo_database_master.ipaddress
        db_port = mongo_database_master[:mongodb][:port]
      end

      template "#{shared_path}/mongoid.yml" do
        source "mongoid.yml.erb"
        owner app["owner"]
        group app["group"]
        mode "644"
        variables(
          :env => node.rails_app.environment,
          :host => db_host,
          :port => db_port,
          :database => "#{app_name}_#{node.rails_app.environment}"
          #:username => app_name,
          #:password => password
        )
      end

      # Delete and symlink our new db config file
      db_config = File.join(release_path, 'config', 'mongoid.yml')
      File.delete(db_config) if File.exists?(db_config)

      link db_config do
        to "#{shared_path}/mongoid.yml"
      end
    else
      Chef::Log.warn("No node with role database_master or mongo_database_master, database.yml not rendered!")
    end

    # ldap.yml for apps with ldap integration
    ldap_master = search(:node, "roles:ldap-server", nil, 0, 1)[0][0]

    # If a ldap master exists
    if ldap_master && File.exists?(File.join(release_path, 'config', 'ldap.yml'))
      template "#{shared_path}/ldap.yml" do
        source "ldap.yml.erb"
        owner app["owner"]
        group app["group"]
        mode "644"
        variables(
          :env => node.rails_app.environment,
          :ldap => ldap_master,
          :ldap_password_policies => node[app_name][:environments][node.rails_app.environment][:ldap_password_policies]
        )
      end

      # Delete and symlink our new db config file
      ldap_config = File.join(release_path, 'config', 'ldap.yml')
      File.delete(ldap_config) if File.exists?(ldap_config)

      link ldap_config do
        to "#{shared_path}/ldap.yml"
      end
    else
      Chef::Log.warn("No node with role ldap-server or ldap.yml does not exist in repo, ldap.yml not rendered!")
    end

    hoptoad_config = File.join(release_path, 'config', 'initializers', 'hoptoad.rb')
    errbit_config = File.join(release_path, 'config', 'initializers', 'errbit.rb')

    File.delete(hoptoad_config) if File.exists?(hoptoad_config)
    File.delete(errbit_config) if File.exists?(errbit_config)

    if errbit_server && node[app_name][:error_notification] && node[app_name][:error_notification][:api_key]
      notifier = node[app_name][:error_notification][:notifier] || "Airbrake"

      template "#{shared_path}/errbit.rb" do
        source "errbit.rb.erb"
        owner app["owner"]
        group app["group"]
        mode "644"
        variables :errbit_server => errbit_server, :api_key => node[app_name][:error_notification][:api_key], :notifier => notifier
      end

      link errbit_config do
        to "#{shared_path}/errbit.rb"
      end
    else
      Chef::Log.warn("No node with role errbit server and app server or no api key specified, errbit.rb not rendered!")
    end

    # We might deploy non-rails application that doesn't have a vendor dir.
    directory "#{release_path}/vendor" do
      owner node.rails_app.user
      group node.rails_app.group
      mode '0755'
    end

    # Bundle Install
    link "#{release_path}/vendor/bundle" do
      to "#{shared_path}/bundle"
    end

    if File.exists?(File.join(release_path, 'Gemfile'))
      gem_servers = search(:node, "roles:gem_server AND roles:app_server") || []
      gem_proxies = search(:node, "roles:gem_proxy AND roles:app_server") || []

      unless gem_servers.empty? || gem_proxies.empty?
        execute "update gemfile sources" do
          command "sed -i 's/^source .*$//' Gemfile && echo '\n' >> Gemfile"
          cwd release_path
        end

        gem_servers.each do |gem_server|
          execute "add gemserver #{gem_server.hostname} to gemfile" do
            command "echo 'source \"https://#{gem_server.fqdn}\"' >> Gemfile"
            cwd release_path
          end
        end

        gem_proxies.each do |gem_proxy|
          execute "add gemproxy #{gem_proxy.hostname} to gemfile" do
            command "echo 'source \"https://#{gem_proxy.fqdn}\"' >> Gemfile"
            cwd release_path
          end
        end
      end

      execute "bundle install --path vendor/bundle" do
        command "cd #{release_path} && bundle install --path vendor/bundle --without test"
      end
    end
  end # before_migrate

  after_restart do
    execute "monit-restart-group" do
      command "monit -g #{app_name} restart"
    end
  end
end

#Backup
settings = node.send(app_name).environments.send(node.rails_app.environment)
if node.roles.include?("backup") && settings.include?('file_backups')
  # Backup Uploaded Media
  settings.file_backups.each do |backup|
    file_backup backup[:name] do
      paths backup[:paths].collect{|path| "#{shared_dir}/#{path}"}
      keep backup[:keep]
      at backup[:at]
      every backup[:every]
    end
  end
end
