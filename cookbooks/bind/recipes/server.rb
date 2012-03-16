#
# Cookbook Name:: bind
# Recipe:: default
#
# Copyright 2011, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

package "bind9"
service "bind9"

if node[:bind][:type] == 'master'
  slaves = search(:node, "roles:dns-slave") || []
else
  slaves = []
end

if node[:bind][:type] == 'slave'
  masters = search(:node, "roles:dhcp-server") || []
  node[:dhcpd][:zones] = masters.first[:dhcpd][:zones]
  node[:dhcpd][:domain] = masters.first[:dhcpd][:domain]
  node[:bind][:forwarders] = masters.first[:bind][:forwarders]
else
  masters = []
end

dns_zones = zones
template "/etc/bind/named.conf" do
  source "named.conf.erb"
  owner "root"
  group "bind"
  mode "0644"
  notifies :restart, resources(:service => "bind9")
end

template "/etc/bind/named.conf.local" do
  source "named.conf.local.erb"
  owner "root"
  group "bind"
  mode "644"
  variables :zones => dns_zones, :slaves => slaves, :masters => masters
  notifies :restart, resources(:service => 'bind9')
end

template "/etc/bind/named.conf.options" do
  source "named.conf.options.erb"
  owner "root"
  group "bind"
  mode "644"
  variables :zones => dns_zones
  notifies :restart, resources(:service => 'bind9')
end

# the slave require a change to apparmor to make zones wriatable
service "apparmor"

template "/etc/apparmor.d/usr.sbin.named" do
  source "usr.sbin.named.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "apparmor")
end

monit_process "bind9" do
  pid_file "/var/run/named/named.pid"
  executable "/etc/init.d/bind9"
end

nameservers = search(:node, "recipes:bind\\:\\:server").collect{ |nameserver| "#{nameserver[:fqdn]}."}
nameservers = nameservers | [ "#{node[:fqdn]}." ]
if nameservers.size < 2
  nameservers << "dummy.#{node[:dhcpd][:domain]}."
end

directory "/etc/bind/zones" do
  owner "bind"
  group "bind"
  mode "0755"
end

directory "/etc/bind/zones/#{node[:bind][:type]}" do
  owner "bind"
  group "bind"
  mode "0755"
end

unless node[:bind][:type] == "slave"
  template "/etc/bind/zones/master/#{node[:dhcpd][:domain]}.db" do
      source "forward.erb"
      owner "root"
      group "bind"
      mode "644"
      variables :zones => dns_zones, :nameservers => nameservers, :domain => node[:dhcpd][:domain]
      notifies :restart, resources(:service => 'bind9')
  end

  node[:dhcpd][:zones].each do |zone, config|
    Chef::Log.info(config.inspect)
    template "/etc/bind/zones/master/#{sub_zone(zone)}.db" do
      source "reverse.erb"
      owner "bind"
      group "bind"
      mode "644"
      variables :nameservers => nameservers, :config => config
      notifies :restart, resources(:service => 'bind9')
    end
  end
end

iptables_rule "input_dns" do
 dport 53
 chain 'INPUT'
 protocol 'udp'
 comment "Dns server accepts dns queries"
end

iptables_rule "output_dns" do
  dport 53
  chain "OUTPUT"
  protocol 'udp'
  comment "Dns server access to forwarders"
end

#Backup
if node.roles.include?("backup") && node.bind.include?('backups')
  # Backup Uploaded Media
  node.bind.backups.each do |backup|
    file_backup "bind" do
      paths ["/etc/bind/zones/#{node[:bind][:type]}"]
      keep backup[:keep]
      every backup[:every]
      at backup[:at]
    end
  end
end
