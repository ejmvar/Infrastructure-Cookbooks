node.splunk.apps.each do |app_name, app|
  cookbook_file "/tmp/#{app[:package_name]}.tar.gz" do
    source "#{app[:package_name]}.tar.gz"
    action :create_if_missing
  end

  bash "extract #{app_name} source" do
    cwd "/tmp"
    code "tar zxf #{app[:package_name]}.tar.gz && \
            mv #{app[:extracted_name]} #{app[:package_name]} && \
            cp -r #{app[:package_name]} #{node.splunk.install_path}/etc/apps/#{app[:extracted_name]}"
    not_if { File.directory?("/tmp/#{app[:package_name]}") }
    notifies :restart, resources(:service => 'splunk'), :immediately
  end
end
