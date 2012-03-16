#
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Joshua Sierles <joshua@37signals.com>
# Cookbook Name:: chef
# Recipe:: client
#
# Copyright 2008-2010, Opscode, Inc
# Copyright 2009, 37signals
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
  ["openbsd", "freebsd", "mac_os_x"] => { "default" => "wheel" },
  "default" => "root"
)

chef_node_name = Chef::Config[:node_name] == node["fqdn"] ? false : Chef::Config[:node_name]

%w{run_path cache_path backup_path log_dir}.each do |key|
  directory node['chef_client'][key] do
    recursive true
    owner "root"
    group root_group
    mode 0755
  end
end

chef_servers = search(:node, 'role:chef_server') || []
template "/etc/chef/client.rb" do
  source "client.rb.erb"
  owner "root"
  group root_group
  mode 0644
  variables :chef_node_name => chef_node_name, :chef_server => chef_servers.first
  notifies :create, "ruby_block[reload_client_config]"
end

chef_servers.each do |chef_server|
  iptables_rule "output_chef_#{chef_server.hostname}" do
    dport 443
    chain 'OUTPUT'
    destination chef_server.ipaddress
    comment "Retrieve data from chef server #{chef_server.hostname}"
  end
end

ruby_block "reload_client_config" do
  block do
    Chef::Config.from_file("/etc/chef/client.rb")
  end
  action :nothing
end
