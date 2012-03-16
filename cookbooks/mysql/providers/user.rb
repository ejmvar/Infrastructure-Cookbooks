include Opscode::Mysql::Database
include Opscode::OpenSSL::Password


action :create_user do
  # Force a require so that it works the first time we run and 
  # the mysql gem is not installed
  begin
    Gem.clear_paths # needed for Chef to find the gem...
    require 'mysql'
  rescue LoadError
    Chef::Log.warn("Missing gem 'mysql'")
  end

  password = new_resource.password || secure_password
  node[:mysql][:users] ||= Mash.new
  node[:mysql][:users][new_resource.username] ||= Mash.new
  node[:mysql][:users][new_resource.username][:password] ||= password
  node[:mysql][:users][new_resource.username][:hosts] ||= Array.new


  # Create this host access if its not yet created
  unless node[:mysql][:users][new_resource.username][:hosts].include?(new_resource.host)
    node[:mysql][:users][new_resource.username][:hosts] << new_resource.host
  end

  db = ::Mysql.new "localhost", "root", node.mysql.server_root_password
  db.query <<-SQL
    GRANT ALL PRIVILEGES ON #{new_resource.database}.* 
      TO '#{new_resource.username}'@'#{new_resource.host}' 
      IDENTIFIED BY '#{node[:mysql][:users][new_resource.username][:password]}';
  SQL

  # Give users for apps replication-ability
  # Give both the slave and client grants so that the dbs can be both master and slaves
  db.query <<-SQL
    GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO '#{new_resource.username}'@'#{new_resource.host}';
  SQL

  if new_resource.admin_privileges
    db.query <<-SQL
      GRANT RELOAD,PROCESS,SUPER,REPLICATION CLIENT ON *.* TO '#{new_resource.username}'@'#{new_resource.host}';
    SQL
  end

  # Save the node so that the attributes are stored on the server
  # This ensures that if we crash, the user's password will be saved for future use
  node.save
end

# Callback invoked by chef
def load_current_resource
end

