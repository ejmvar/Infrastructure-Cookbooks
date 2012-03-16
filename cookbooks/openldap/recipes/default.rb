#
# Cookbook Name:: openldap
# Recipe:: default
#
# Copyright 2008-2009, Opscode, Inc.
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
#
#Ldap Servers
if node.roles.include?("ldap-server")
  ldap = node
else
  ldap = search(:node, "roles:ldap-server")[0]
end

replicas = search(:node, "roles:ldap-replica") || []
replicas | [ node ] if node.run_list.include?("role:ldap-replica")

Chef::Log.info("Ldap server found at #{ldap[:ipaddress]}") if ldap

if ldap
 package "ldap-auth-client"
 #Install nscd to fix bug where ldap users are unable to sudo
 include_recipe "nscd"

 package "ldap-utils"

 groups = node[:openldap][:user_groups]
 groups << node.chef_environment
  template "/etc/ldap.conf" do
    source "ldap.conf.erb"
    owner "root"
    group "root"
    variables :ldap => ldap, :replicas => replicas, :groups => groups
    mode "0644"
  end

  template "/etc/ldap/ldap.conf" do
    source "openldap.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :restart, resources(:service => 'nscd'), :immediately
  end

  cookbook_file "/etc/auth-client-config/profile.d/open_ldap" do
    source "open_ldap"
    owner "root"
    group "root"
    mode "0644"
  end

  execute "auth-client-config -a -p open_ldap"

  template "/etc/security/group.conf" do
    source "group.conf.erb"
    mode "0644"
    owner "root"
    group "root"
  end

  ([ ldap ] | replicas).each do |ldap_server|
    iptables_rule "output_ldap_#{ldap_server.hostname}" do
      dport 389
      chain 'OUTPUT'
      destination ldap_server.ipaddress
      comment "Ldap:// user authentication: #{ldap_server.hostname}"
    end

    iptables_rule "output_ldaps_#{ldap_server.hostname}" do
      dport 636
      chain 'OUTPUT'
      destination ldap_server.ipaddress
      comment "Ldaps:// user authentication: #{ldap_server.hostname}"
    end

    iptables_rule "input_ldap_#{ldap_server.hostname}" do
      sport 389
      chain 'INPUT'
      source ldap_server.ipaddress
      comment "Ldap:// user authentication: #{ldap_server.hostname}"
    end

    iptables_rule "input_ldaps_#{ldap_server.hostname}" do
      sport 636
      chain 'INPUT'
      source ldap_server.ipaddress
      comment "Ldaps:// user authentication: #{ldap_server.hostname}"
    end
  end
end
