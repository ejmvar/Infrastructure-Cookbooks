#
# Cookbook Name:: dhcpd
# Recipe:: default
#
# Copyright 2010, 37signals
#
# All rights reserved - Do Not Redistribute
#

#pxe address
nameservers = search(:node, "roles:dhcp-server") || []

nameservers = nameservers | (search(:node, "recipes:bind\\:\\:server") || [])

nameservers.each do | nameserver |
   iptables_rule "output_dns_#{nameserver.hostname}_udp" do
     dport 53
     chain 'OUTPUT'
     protocol 'udp'
     destination nameserver.ipaddress
     comment "Resolve dns entries at #{nameserver.hostname}"
   end

   iptables_rule "output_dns_#{nameserver.hostname}_tcp" do
     dport 53
     chain 'OUTPUT'
     destination nameserver.ipaddress
     comment "Resolve dns entries at #{nameserver.hostname}"
   end

   iptables_rule "output_dhcp_#{nameserver.hostname}_udp" do
     dport 67
     sport 68
     chain 'OUTPUT'
     protocol 'udp'
     destination nameserver.ipaddress
     comment "Dhcp namserver.hostname"
   end
end

domains = nameservers.collect {|x| x[:dhcpd][:domain] }.uniq
ips = nameservers.collect {|x| x[:ipaddress]}.uniq
template "/etc/resolv.conf" do
  source "resolv.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables :nameservers => ips, :domains => domains
  not_if { nameservers.empty? }
end
