define :file_backup, :paths => [], :keep => 24, :every => '1.day', :at => nil, :use_sudo => false do
  archives = {"#{params[:name]}" => params[:paths]}

  job = {:archives => archives, :keep => params[:keep], :every => params[:every], :at => params[:at], :use_sudo => params[:use_sudo] }
  name = "#{params[:name]}_files_#{params[:every].gsub('.', '_')}"
  node[:backup][:jobs][name] = job
  node.save
end
