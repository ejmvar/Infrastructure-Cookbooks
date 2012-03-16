#
# Cookbook Name:: passenger_nginx
# Recipe:: default
#
# Copyright 2010, VersaPay Corporation
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'nginx::install_packages_and_extract_sources'

gem_package 'passenger' do
  action :install
  version node[:passenger][:version]
end

execute "install-nginx" do
  # Install nginx from source. Set error-log-path at compile time.
  command %{ passenger-install-nginx-module                 \
    --auto                                                  \
    --prefix=#{node[:nginx][:install_path]}                 \
    --nginx-source-dir=/tmp/nginx-#{node[:nginx][:version]} \
    --extra-configure-flags="                               \
      --error-log-path=#{node[:nginx][:log_dir]}/error.log  \
      #{node[:nginx][:extra_configure_flags]}               \
      "}
  not_if { File.exists?(node[:nginx][:install_path]) }
end

include_recipe 'nginx::setup_service_and_common_configuration'

template "passenger.conf" do
  path "#{node[:nginx][:conf_dir]}/conf.d/passenger.conf"
  source "passenger.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "nginx"), :immediately
end

