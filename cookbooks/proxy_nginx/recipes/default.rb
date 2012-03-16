#
# Cookbook Name:: proxy_nginx
# Recipe:: default
#
# Copyright 2010, VersaPay
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'nginx::install_packages_and_extract_sources'

execute "install-nginx" do
  # Install nginx from source. Set error-log-path at compile time.
  command %{
    cd "/tmp" &&                                                \
    tar xzf nginx-#{node.nginx.version}.tar.gz &&               \
    cd nginx-#{node.nginx.version} &&                           \
    ./configure #{node.nginx.extra_configure_flags}             \
      --prefix=#{node[:nginx][:install_path]}                   \
      --error-log-path=#{node[:nginx][:log_dir]}/error.log      \
      #{node[:nginx][:extra_configure_flags]}                   \
    && make && make install
  }
  not_if { File.exists?(node[:nginx][:install_path]) }
end

include_recipe 'nginx::setup_service_and_common_configuration'

include_recipe 'proxy_nginx::iptables'

# setup reverse proxy configurations
node.rails_apps.each do |app_name|
  fqdn = node[app_name].environments[node.rails_app.environment].fqdn || node.fqdn
  app_servers = search(:node, "roles:#{app_name} AND chef_environment:#{node.chef_environment} AND roles:app_server")

  template "#{node[:nginx][:conf_dir]}/sites-available/proxy_#{app_name}" do
    source "proxy_nginx.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
      :fqdn => fqdn,
      :app_servers => app_servers,
      :app_name => app_name
    )
    notifies :restart, resources(:service => "nginx")
  end

  ["/data", "/data/nginx-error"].each do |dir|
	directory dir do
	  owner "root"
	  group "root"
	  mode 0755
	end
  end
  
  # Error page for nginx
  template "/data/nginx-error/error.html" do
	source "error-page.html"
	owner "root"
	group "root"
	mode 0644
  end

  # TODO run service nginx force-reload if cert has changed
  ssl_cert fqdn # generate ssl_cert

  nginx_site "proxy_#{app_name}" do
    notifies :restart, resources(:service => "nginx")
  end
end

