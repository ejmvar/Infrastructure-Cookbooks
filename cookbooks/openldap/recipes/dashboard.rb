package 'php5-ldap'
package 'phpldapadmin'

node['apache']['listen_ports'] << "443" unless node['apache']['listen_ports'].include?("443")

include_recipe "apache2"
include_recipe "apache2::mod_ssl"
include_recipe "apache2::mod_headers"

#Ldap Servers
if node[:openldap][:dashboard][:local_ldap]
  ldap = node
else
  ldaps = search(:node, "roles:ldap-server") || []
  if ldaps.length > 0
    ldap = ldaps[0]
  end
end
Chef::Log.info("Ldap server found at #{ldap[:ipaddress]}") if ldap

template "/etc/phpldapadmin/config.php" do
  source "config.php.erb"
  owner "root"
  group "www-data"
  mode "0644"
  variables :ldap => ldap
end

directory "/etc/ldap/ssl" do
  owner "root"
  group "root"
  mode "700"
end

cookbook_file "/etc/ldap/ssl/#{node[:fqdn]}.key" do
  source "#{node[:fqdn]}.key"
  mode "0640"
  owner "root"
  group "root"
end

cookbook_file "/etc/ldap/ssl/#{node[:fqdn]}.crt" do
  source "#{node[:fqdn]}.crt"
  mode "0644"
  owner "root"
  group "root"
end

# Let's disable the default website
file '/etc/apache2/sites-enabled/000-default' do
  action :delete
end

web_app node.fqdn do
  template "phpldapadmin.conf.erb"
  server_name node.fqdn
  server_aliases ["ldap.#{node.fqdn}"]
end
