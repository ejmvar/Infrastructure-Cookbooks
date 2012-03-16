define :mongo_backup, :keep => 24, :host => 'localhost', :database => nil, :every => '1.day', :port => 27017, :at => nil do
  ruby_block "setup mongo backups" do
    block do
      database = {:host => params[:host], :port => params[:port]}
      name = "#{params[:database]}_db_#{params[:every].gsub('.','_')}"
      job = { :keep => params[:keep], :every => params[:every], :mongo_databases => {}, :at => params[:at]}
      job[:mongo_databases][params[:database]] = database
      node[:backup][:jobs][name] = job
      node.save
    end
    action :create
  end
end
