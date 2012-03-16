include_recipe "mysql::server"
#include_recipe "iptables"
include_recipe "ssh"

template "/etc/mysql/conf.d/slave.cnf" do
  source "slave.cnf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, resources(:service => "mysql"), :immediately
end

# A spot to store references to master dbs
node[:mysql][:masters] = Mash.new

node.rails_apps.each do |app_name|

  # Find the db master server
  if node[app_name][:environments][node.rails_app.environment][:external_db_master]
    dbmaster = node[app_name][:environments][node.rails_app.environment][:external_db_master]
    db_name = node[app_name][:environments][node.rails_app.environment][:external_db_master][:dbname]
  else
    dbmaster = node[:mysql][:masters][app_name] ? search(:node, "ipaddress:#{node[:mysql][:masters][app_name]}")[0] : search(:node, "role:#{app_name} AND role:database_master AND chef_environment:#{node.chef_environment}")[0]
  end


  if dbmaster
    db_name ||= "#{app_name}_#{node.rails_app.environment}"

    mysql_database "Create application database" do
      host      "localhost"
      username  "root"
      password  node[:mysql][:server_root_password]
      database  db_name
      action    :create_db
    end

    # We store it just in case we boot up more masterdb's we don't want it changing on us
    node[:mysql][:masters][app_name] = dbmaster[:ipaddress]

    # Should we tunnel our db connection
    if node[app_name][:environments][node.rails_app.environment][:secure_db_connection]
      master_host = '127.0.0.1'
      master_port = 4406

      # Setup Iptables rule for ssh tunnel
      iptables_rule "output_db_master_#{dbmaster[:hostname]}" do
        destination dbmaster[:ipaddress]
        dport 22
        chain 'OUTPUT'
        comment "Allow ssh tunnel connection to db master #{dbmaster[:fqdn]}"
      end

      # Setup an ssh tunnel
      ssh_tunnel "#{app_name}-#{node.rails_app.environment}-db-slave-tunnel" do
        port 4406
        host dbmaster[:ipaddress]
        host_port 3306
      end
    else
      # Setup Iptables rule for db master connection
      iptables_rule "output_db_master_#{dbmaster[:hostname]}" do
        destination dbmaster[:ipaddress]
        dport 3306
        chain 'OUTPUT'
        comment "Allow mysql connection to db master #{dbmaster[:fqdn]}"
      end

      master_host = dbmaster[:ipaddress]
      master_port = 3306
    end

    # To reset an existing slave, run the following:
    # rm /home/deploy/.eft3-slave-imported
    # echo 'STOP SLAVE; RESET SLAVE; CHANGE MASTER TO MASTER_HOST=""; RESET SLAVE; DROP DATABASE eft3_yourenv' | mysql -u root -pTHEPASSWORD
    # sudo chef-client -V

    bash "setup-slave" do
      sql = []
      sql << "CHANGE MASTER TO MASTER_HOST=\\'#{master_host}\\'"
      sql << "MASTER_PORT=#{master_port}"
      sql << "MASTER_USER=\\'#{app_name}\\'"
      sql << "MASTER_PASSWORD=\\'#{dbmaster[:mysql][:users][app_name][:password]}\\'"
      
      code <<-SQL
        echo #{sql.join(',')} | mysql -u root -p#{node.mysql.server_root_password}
      SQL
      not_if "echo 'SHOW SLAVE STATUS\\G' | mysql -u root -p#{node.mysql.server_root_password} | grep 'Master_Host: #{master_host}'"
    end

    bash "retrieve-dump-from-master" do
      # Touch this file once data is successfully imported
      test_file = "/home/deploy/.#{app_name}-slave-imported"

      code <<-SQL
        mysqldump --single-transaction --master-data=1 -h '#{master_host}' -P #{master_port} -u #{app_name} -p#{dbmaster[:mysql][:users][app_name][:password]} #{db_name} | mysql -u root -p#{node.mysql.server_root_password} #{db_name} && touch #{test_file}
      SQL

      not_if { ::File.exists?(test_file) }
    end


    bash "start-slave" do
      code <<-SQL
        echo START SLAVE | mysql -u root -p#{node.mysql.server_root_password}
      SQL
    end

    settings = node.send(app_name).environments.send(node.rails_app.environment)
    if node.roles.include?("backup") && settings.include?('db_slave_backups')
     settings.db_slave_backups.each do |config|
        # Backup the application Database
        mysql_backup do
          keep config[:keep]
          every config[:every]
          database db_name
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
  else
    Chef::Log.warn("Could not find a db master for this slave")
  end
end
