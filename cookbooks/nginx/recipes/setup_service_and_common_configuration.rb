#
# Cookbook Name:: nginx
# Recipe:: setup_service_and_common_configuration
#
# Setup nginx service, directories and common configuration
#
# Copyright 2010, VersaPay
#
# All rights reserved - Do Not Redistribute
#


# /opt/nginx => /opt/nginx-VERSION
link node[:nginx][:dir] do
  to node[:nginx][:install_path]
end

# Setup nginx init.d script
template "/etc/init.d/nginx" do
  source "nginx.init.erb"
  owner "root"
  group "root"
  mode "0755"
end

# Register nginx as a service
service "nginx" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
  subscribes :restart, resources(:execute => "install-nginx")
end

# Create log directory
directory node[:nginx][:log_dir] do
  owner node[:nginx][:user]
  group node[:nginx][:user]
  mode "0755"
  recursive true
end

# Delete useless directories generated during nginx install
%w(conf html logs).each do |dir|
  directory "#{node[:nginx][:dir]}/#{dir}" do
    action :delete
    recursive true
  end
end

# Create configuration directories
%w{ sites-available sites-enabled conf.d }.each do |dir|
  directory "#{node[:nginx][:conf_dir]}/#{dir}" do
    owner "root"
    group "root"
    mode "0755"
    recursive true
  end
end

# Generate nginx configuration files
template "nginx.conf" do
  path "#{node[:nginx][:conf_dir]}/nginx.conf"
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "nginx"), :immediately
end

cookbook_file "#{node[:nginx][:conf_dir]}/mime.types" do
  source "mime.types"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "nginx"), :immediately
end

# Add utilities to enable / disable sites
%w{nxensite nxdissite}.each do |nxscript|
  template "/usr/sbin/#{nxscript}" do
    source "#{nxscript}.erb"
    mode "0755"
    owner "root"
    group "root"
  end
end

# Add monit
monit_process :nginx do
  pid_file "/var/run/nginx.pid"
  executable "/etc/init.d/nginx"
end
