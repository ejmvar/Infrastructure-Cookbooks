#
# Author:: Joshua Sierles <joshua@37signals.com>
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: nagios
# Recipe:: server
#
# Copyright 2009, 37signals
# Copyright 2009-2010, Opscode, Inc
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

include_recipe "apache2"
include_recipe "apache2::mod_ssl"
include_recipe "apache2::mod_rewrite"
include_recipe "nagios::client"

nodes = search(:node, "name:*")
if nodes.empty?
  Chef::Log.info("No nodes returned from search, using this node so hosts.cfg has data")
  nodes = Array.new
  nodes << node
end

# Get all the contacts for nagios
contacts = node.nagios.contacts.collect do |id, contact|
  contact.merge({:id => id})
end

role_list = Array.new
service_hosts= Hash.new
search(:role, "*:*") do |r|
  role_list << r.name
  search(:node, "roles:#{r.name}") do |n|
    service_hosts[r.name] = n['hostname']
  end
end

if node[:public_domain]
  public_domain = node[:public_domain]
else
  public_domain = node[:domain]
end

%w{ nagios3 nagios-nrpe-plugin nagios-images }.each do |pkg|
  package pkg
end

service "nagios3" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable ]
end

monit_process "nagios3" do
  pid_file "/var/run/nagios3/nagios3.pid"
  executable "/etc/init.d/nagios3"
  user "nagios"
end

nagios_conf "nagios" do
  config_subdir false
end

directory "#{node[:nagios][:dir]}/dist" do
  owner "nagios"
  group "nagios"
  mode "0755"
end

directory node[:nagios][:state_dir] do
  owner "nagios"
  group "nagios"
  mode "0751"
end

directory "#{node[:nagios][:state_dir]}/rw" do
  owner "nagios"
  group node[:apache][:user]
  mode "2710"
end

execute "archive default nagios object definitions" do
  command "mv #{node[:nagios][:dir]}/conf.d/*_nagios*.cfg #{node[:nagios][:dir]}/dist"
  not_if { Dir.glob(node[:nagios][:dir] + "/conf.d/*_nagios*.cfg").empty? }
end

file "#{node[:apache][:dir]}/conf.d/nagios3.conf" do
  action :delete
end

template "#{node[:nagios][:dir]}/htpasswd.users" do
  source "htpasswd.users.erb"
  owner "nagios"
  group node[:apache][:user]
  mode 0640
end

apache_site "000-default" do
  enable false
end

template "#{node[:apache][:dir]}/sites-available/nagios3.conf" do
  source "apache2.conf.erb"
  mode 0644
  variables :public_domain => public_domain
  if File.symlink?("#{node[:apache][:dir]}/sites-enabled/nagios3.conf")
    notifies :reload, resources(:service => "apache2")
  end
end

apache_site "nagios3.conf"

iptables_rule "input_nagios_webui" do
  dport 80
  chain 'INPUT'
  comment 'nagios webui'
end

iptables_rule "output_nagios_nrpe" do
  dport 5666
  destination 'internal'
  chain 'OUTPUT'
  comment 'nagios nrpe: remote plug-in execution'
end

iptables_rule "input_nagios_nrpe_on_spt" do
  sport 5666
  source 'internal'
  chain 'INPUT'
  comment 'nagios nrpe: remote plug-in execution'
end

iptables_rule "output_nagios_check_ssh" do
  dport 22
  destination 'internal'
  chain 'OUTPUT'
  comment 'nagios check SSH connectivity'
end

iptables_rule "output_nagios_check_http" do
  dport 80
  destination 'internal'
  chain 'OUTPUT'
  comment 'nagios check HTTP connectivity'
end

iptables_rule "input_nagios_check_http" do
  sport 80
  source 'internal'
  chain 'INPUT'
  comment 'nagios recieve check HTTP connectivity'
end

iptables_rule "output_nagios_check_https" do
  dport 443
  destination 'internal'
  chain 'OUTPUT'
  comment 'nagios check HTTPS connectivity'
end

iptables_rule "input_nagios_check_https" do
  sport 443
  source 'internal'
  chain 'INPUT'
  comment 'nagios recieve check HTTPS connectivity'
end

iptables_rule "output_nagios_check_ping" do
  protocol 'icmp --icmp-type echo-request'
  destination 'internal'
  chain 'OUTPUT'
  comment 'nagios check ping'
end

iptables_rule "output_nagios_clickatel" do
  dport 80
  chain 'OUTPUT'
  destination '196.5.254.66'
  comment 'Allow connection to clickatel to send text mesaages for nagios alerts'
end

%w{ nagios cgi }.each do |conf|
  nagios_conf conf do
    config_subdir false
  end
end

%w{ commands templates timeperiods}.each do |conf|
  nagios_conf conf
end

nagios_conf "services" do
  variables :service_hosts => service_hosts
end

nagios_conf "contacts" do
  variables :contacts => contacts
end

nagios_conf "hostgroups" do
  variables :roles => role_list
end

nagios_conf "hosts" do
  variables :nodes => nodes
end

nagios_conf "overrides" do
  variables :nodes => nodes
end
