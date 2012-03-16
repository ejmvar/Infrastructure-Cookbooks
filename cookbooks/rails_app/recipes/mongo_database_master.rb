include_recipe "ssh"

node.rails_apps.each do |app_name|
  # Add user priveleges for each app server
  # User's only have access locally because they are ssh tunneling in
  if node.roles.include?(app_name) && (node.roles.include?('app_server') || node.roles.include?('utility_server'))
    database_servers = [ node ]
  else
    database_servers = []
  end

  database_servers = database_servers | search(:node, "run_list:(role:#{app_name}) AND chef_environment:#{node.chef_environment} AND (run_list:(role:app_server) OR run_list(role:utility_server))")
  database_servers.each do |app_server|
    ssh_authorization do
      from app_server
    end
  end

  settings = node.send(app_name).environments.send(node.rails_app.environment)
  if node.roles.include?("backup") && settings.include?('db_master_backups')
   settings.db_master_backups.each do |config|
      # Backup the application Database
      mongo_backup do
        keep config[:keep]
        every config[:every]
        at config[:at]
        database "#{app_name}_#{node.rails_app.environment}"
      end
    end
  end
end
