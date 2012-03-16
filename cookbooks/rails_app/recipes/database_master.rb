include_recipe "mysql"
include_recipe "ssh"

node.rails_apps.each do |app_name|

  #
  # Ensure that the db exists
  #

  mysql_database "Create application database" do
    host      "localhost"
    username  "root"
    password  node[:mysql][:server_root_password]
    database  "#{app_name}_#{node.rails_app.environment}"
    action    :create_db
  end

  # Add user priveleges for each app server
  # User's only have access locally because they are ssh tunneling in
  if node.roles.include?(app_name) && (node.roles.include?('app_server') || node.roles.include?('utility_server'))
    database_servers = [ node ]
  else
    database_servers = []
  end

  database_servers = database_servers | search(:node, "run_list:(role:#{app_name}) AND chef_environment:#{node.chef_environment} AND (run_list:(role:app_server) OR run_list:(role:utility_server))")
  database_servers.each do |app_server|
    mysql_user "Create application user" do
      username  app_name
      host      node.ipaddress
      database  "#{app_name}_#{node.rails_app.environment}"
      action    :create_user
    end

    ssh_authorization do
      from app_server
    end
  end

  # Give slave's admin access (reload and process)
  search(:node, "run_list:(role:#{app_name}) AND (run_list:(role:database_slave)) AND chef_environment:#{node.chef_environment}").each do |slave|
    mysql_user "Create slave root access" do
      username          app_name
      host              node.ipaddress
      database          "#{app_name}_#{node.rails_app.environment}"
      admin_privileges  true
      action            :create_user
    end

    iptables_rule "input_mysql_slave_#{slave.hostname}" do
      chain "INPUT"
      dport 3306
      source slave.ipaddress
      comment "Allow slave mysql access for #{slave.fqdn}"
    end

	# Slave server requires ssh access to db master
    ssh_authorization do
      from slave
    end
  end

  if node[app_name][:environments][node.rails_app.environment][:external_slaves]
    node[app_name][:environments][node.rails_app.environment][:external_slaves].each do |slave|
      mysql_user "Create slave root access" do
        username          app_name
        host              node.ipaddress
        database          "#{app_name}_#{node.rails_app.environment}"
        admin_privileges  true
        action            :create_user
      end

      iptables_rule "input_external_mysql_slave_#{slave[:ipaddress].gsub('.','_')}" do
        chain "INPUT"
        dport 3306
        source slave[:ipaddress]
        comment "Allow external slave mysql access for #{slave[:ipaddress]}"
      end

      ssh_authorization do
        key slave[:key]
      end
    end
  end

  settings = node.send(app_name).environments.send(node.rails_app.environment)
  if node.roles.include?("backup") && settings.include?('db_master_backups')
   settings.db_master_backups.each do |config|
      # Backup the application Database
      mysql_backup do
        keep config[:keep]
        every config[:every]
        database "#{app_name}_#{node.rails_app.environment}"
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
end
