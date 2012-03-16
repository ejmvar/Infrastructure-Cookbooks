#
# Author:: Joshua Timberman <joshua@opscode.com>
# Cookbook Name:: chef-server
# Recipe:: apache-proxy
#
# Copyright 2009-2011, Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

root_group = value_for_platform(
  "openbsd" => { "default" => "wheel" },
  "freebsd" => { "default" => "wheel" },
  "default" => "root"
)

node['apache']['listen_ports'] << "443" unless node['apache']['listen_ports'].include?("443")
if node['chef_server']['webui_enabled']
  node['apache']['listen_ports'] << "444" unless node['apache']['listen_ports'].include?("444")
end

include_recipe "apache2"
include_recipe "apache2::mod_ssl"
include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_http"
include_recipe "apache2::mod_proxy_balancer"
include_recipe "apache2::mod_rewrite"
include_recipe "apache2::mod_headers"
include_recipe "apache2::mod_expires"
include_recipe "apache2::mod_deflate"

directory "/etc/chef/ssl" do
  owner "chef"
  group root_group
  mode "700"
end

ssl_cert node.fqdn do
  destination "/etc/chef/ssl"
  owner "chef"
  group root_group
end

web_app "chef-server-proxy" do
  template "chef_server.conf.erb"
  server_name "#{node[:fqdn]}"
  server_aliases [ node['hostname'], 'chef-server-proxy', "chef.#{node['domain']}" ]
  log_dir node['apache']['log_dir']
end

ruby_block "update_chef_to_ssl" do
  block do
    Chef::Config[:chef_server_url] = "https://#{node[:fqdn]}"
    Chef::Config[:ssl_ca_path] = node['certificate-authority']['ca_cert']
    Chef::Config[:ssl_verify_mode] = :verify_peer
    node['chef_client']['server_url'] = "https://#{node[:fqdn]}"
    node.save
  end
  action :create
  not_if { Chef::Config[:chef_server_url] = "https://#{node[:fqdn]}" }
end

service "apache2" do
  action :restart
end
