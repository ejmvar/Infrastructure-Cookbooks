#
# Cookbook Name:: wordpress
# Recipe:: default
#
# Copyright 2009-2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


node.wordpress.dir = node.wordpress.base_dir + node.wordpress.environments.send(node.chef_environment).fqdn

include_recipe "apache2"
include_recipe "mysql::server"

#
# Setup database
#
mysql_database "Create #{node.wordpress.db.database} database" do
  database  node.wordpress.db.database
  host      "localhost"
  username  "root"
  password  node[:mysql][:server_root_password]
  action    :create_db
end

mysql_user "Create #{node.wordpress.db.user} user" do
  username          node.wordpress.db.user
  host              "localhost"
  database          node.wordpress.db.database
  action            :create_user
end

if node[:wordpress][:environments][node.rails_app.environment][:external_slaves]
  node[:wordpress][:environments][node.rails_app.environment][:external_slaves].each do |slave|
    mysql_user "Create slave root access" do
      username          node.wordpress.db.user
      host              slave[:ipaddress]
      database          node.wordpress.db.database
      admin_privileges  true
      action            :create_user
    end

    ssh_authorization do
      key slave[:key]
    end
  end
end

#
# Install packages and apache modules
#
packages = node.wordpress.packages
packages.each do |pkg, ver|
  package pkg do
    action :install
    version ver if ver && !ver.empty?
    notifies :restart, resources(:service => "apache2")
  end
end

apache_modules = node.wordpress.apache_modules
apache_modules.each do |mod|
  apache_module mod do
    notifies :restart, resources(:service => "apache2")
  end
end

#
# Let's deploy
#

# Create directories to deploy the wordpress website
base_dir = node.wordpress.dir
shared_dir = base_dir + '/shared'
current_dir = base_dir + '/current'

directory shared_dir do
  owner node.apache.user
  group node.apache.user
  mode '0755'
  recursive true
end


# Setup deploy-ssh-wrapper
# Note: This is a mad workaround made in opscode. The resource deploy_revision
# will use it to git clone the app
if node.wordpress.attribute?(:deploy_key)
  deploy_key_path = shared_dir + '/deploy_key'

  ruby_block "write_key" do
    block do
      File.open(deploy_key_path, "w") do |f|
        f.print(node.wordpress.deploy_key)
      end
    end
    # always overwrite the deploy_key with the one from the role
  end

  # Make the deploy_key readable by owner only
  file deploy_key_path do
    owner node.apache.user
    group node.apache.user
    mode '0600'
  end

  template "#{shared_dir}/deploy-ssh-wrapper" do
    source "deploy-ssh-wrapper.erb"
    owner node.apache.user
    group node.apache.user
    mode "0755"
    variables(:deploy_key_path => deploy_key_path)
  end
end


deploy_revision "wordpress" do
  action (node[:force_deploy] ? :force_deploy : :deploy)

  revision node.wordpress.environments.send(node.chef_environment).branch
  repository node.wordpress.repository

  user node.apache.user
  group node.apache.user

  deploy_to base_dir

  ssh_wrapper "#{shared_dir}/deploy-ssh-wrapper" if node.wordpress.attribute?(:deploy_key)


  symlinks({}) # This method forces the target to have the same name as the source
  symlink_before_migrate({}) # do not run default rails symlinks

  # Let's make our own symlink system
  before_symlink do
    da_symlinks = { "wp-config.php" => "wp-config.php", "uploads" => "wp-content/uploads", 
      "htaccess" => ".htaccess", "w3tc_minify" => "wp-content/w3tc/min" }
    da_symlinks.each do |shared, current|
      execute "Move #{shared} to the shared directory. (First deploy!)" do
        command "mv #{release_path}/#{current} #{shared_dir}/#{shared} && chmod -R a+w #{shared_dir}/#{shared}"
        only_if { File.exists?("#{release_path}/#{current}") && 
                    !File.exists?(shared_dir + '/' + shared) }
      end

      execute "Delete #{shared} from current release" do
        command "rm -fr #{release_path}/#{current}"
        only_if { File.exists?("#{release_path}/#{current}") }
      end

      link "#{release_path}/#{current}" do
        to  "#{shared_dir}/#{shared}"
      end
    end

    # Symlink w3-total-cache-config for current environment
    if node[:rails_app] && node[:rails_app][:environment] && File.exists?("#{release_path}/wp-content/w3-total-cache-config.#{node.rails_app.environment}.php")
      link "#{release_path}/wp-content/w3-total-cache-config.php" do
        to  "#{release_path}/wp-content/w3-total-cache-config.#{node.rails_app.environment}.php"
      end
    end
  end
end


template "#{shared_dir}/wp-config.php" do
  source "wp-config.php.erb"
  owner node.apache.user
  group node.apache.user
  mode "0644"
  variables(
    :database        => node[:wordpress][:db][:database],
    :user            => node[:wordpress][:db][:user],
    # Value will be grabbed at run time
    #:password        => node.mysql.users[node.wordpress.db.user].password,
    :auth_key        => node[:wordpress][:keys][:auth],
    :secure_auth_key => node[:wordpress][:keys][:secure_auth],
    :logged_in_key   => node[:wordpress][:keys][:logged_in],
    :nonce_key       => node[:wordpress][:keys][:nonce]
  )
end

# 
# Apache config
#

include_recipe %w{php::php5 php::module_mysql}

# Let's disable the default website
file '/etc/apache2/sites-enabled/000-default' do
  action :delete
end

web_app node.wordpress.environments.send(node.chef_environment).fqdn do
  template "wordpress.conf.erb"
  docroot current_dir
  server_name node.wordpress.environments.send(node.chef_environment).fqdn
  server_aliases node.fqdn
end

settings = node.wordpress.environments.send(node.chef_environment)
# BACKUPS
if node.roles.include?("backup")
  if settings.include?('db_master_backups')
    settings.db_master_backups.each do |config|
      # Backup the wordpress Database
      mysql_backup do
        keep config[:keep]
        every config[:every]
        database node.wordpress.db.database
        at config[:at]
      end

      # Backup the mysql user and preferences database
      mysql_backup do
        keep config[:keep]
        every config[:every]
        database 'mysql'
        at config[:at]
      end
    end
  end

  if settings.include?('file_backups')
    # Backup Uploaded Media
    settings.file_backups.each do |backup|
      file_backup backup[:name] do
        paths backup[:paths].collect{|path| "#{shared_path}/#{path}"}
        keep backup[:keep]
        every backup[:every]
        at backup[:at]
      end
    end
  end
end

#
# Iptable goodness
#

iptables_rule "input_http" do
  dport 80
  chain 'INPUT'
  comment 'Allow unsecure http connections for webservice'
end
