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
#package "ldapscripts"
#conf_dir = "/etc/ldapscripts"

conf_dir = "/usr/local/etc/ldapscripts"

cookbook_file "/tmp/ldapscripts-2.0.1.tgz" do
  source "ldapscripts-2.0.1.tgz"
end

execute "tar -xf ldapscripts-2.0.1.tgz" do
  user "root"
  cwd "/tmp"
end

execute "make install" do
  cwd "/tmp/ldapscripts-2.0.1"
  user "root"
end

#Ldap Servers
ldaps = search(:node, "roles:ldap-server") || []
if ldaps.length > 0
  ldap = ldaps[0]
else
  ldap = node
end
Chef::Log.info("Ldap server found at #{ldap[:ipaddress]}") if ldap

template "#{conf_dir}/ldapadduser.template" do
  source "ldapadduser.template.erb"
  owner "root"
  group "root"
  mode "0644"
end

template "#{conf_dir}/ldapscripts.conf" do
  source "ldapscripts.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables :ldap => ldap
end

execute "echo -n '#{ldap[:openldap][:server][:admin_password]}' > #{conf_dir}/ldapscripts.passwd && chmod 600 #{conf_dir}/ldapscripts.passwd" do
  user "root"
end
