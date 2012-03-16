define :mysql_backup, :keep => 24, :host => 'localhost', :database => nil, :every => '1.day', :port => 3306, :socket => nil, :at => nil do
  mysql_user "Create backup user" do
    username  node[:backup][:mysql_backup_user]
    host      params[:host]
    database  "*"
    action    :create_user
  end


  ruby_block "setup mysql backups" do
    block do
      database = {:username => node[:backup][:mysql_backup_user], :password => node[:mysql][:users][node[:backup][:mysql_backup_user]].password, :host => params[:host], :port => params[:port], :socket => params[:socket]}

      name = "#{params[:database]}_db_#{params[:every].gsub('.','_')}"
      job = { :at => params[:at], :keep => params[:keep], :every => params[:every], :mysql_databases => {}}
      job[:mysql_databases][params[:database]] = database
      node[:backup][:jobs][name] = job
      node.save
    end
    action :create
  end
end
