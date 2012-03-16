#
# Cookbook Name:: dhcpd
# Recipe:: default
#
# Copyright 2011, Versapay
#
# All rights reserved - Do Not Redistribute
#

package "dhcp3-server"
service "dhcp3-server"

nameservers = search(:node, "recipes:bind\\:\\:server").collect{ |nameserver| nameserver[:ipaddress]}
if nameservers.empty?
  nameservers = ['8.8.8.8', '8.8.4.4']
end

template "/etc/default/dhcp3-server" do
  source "dhcp3-server.default.erb"
  owner "root"
  group "root"
  mode 0644
  notifies(:restart, resources(:service => "dhcp3-server"))
end

hosts = all_hosts
subnets = zones
template "/etc/dhcp3/dhcpd.conf" do
  source "dhcpd.conf.erb"
  owner "root"
  group "root"
  mode "644"
  variables :nameservers => nameservers, :hosts => hosts, :subnets => subnets
  notifies(:restart, resources(:service => "dhcp3-server"))
end

iptables_rule "output_dhcp" do
  dport 67
  chain 'OUTPUT'
  protocol 'udp'
  comment "Allow output of dhcp"
end
