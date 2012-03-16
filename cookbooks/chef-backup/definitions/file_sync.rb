define :file_sync, :paths => [], :every => '1.day', :at => nil do
  #TODO MAKE SURE BUCKET EXISTS
  job = {:sync_directories => params[:paths], :every => params[:every], :at => params[:at], :type => 'sync' }
  name = "#{params[:name]}_files_#{params[:every].gsub('.', '_')}"
  node[:backup][:jobs][name] = job
  node.save
end
