define :command_backup, :command => nil, :post_command => nil, :paths => [], :keep => 24, :every => '1.day', :at => nil do
  archives = {"#{params[:name]}" => params[:paths]}

  job = {:command => params[:command], :archives => archives, :keep => params[:keep], :every => params[:every], :at => params[:at] }
  job[:post_command] = params[:post_command] if params[:post_command]
  name = "#{params[:name]}_files_#{params[:every].gsub('.', '_')}"
  node[:backup][:jobs][name] = job
  node.save
end
