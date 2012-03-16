package 'slapd'
package 'ldap-utils'
package 'python-ldap' if node[:openldap][:server][:nova]

service "slapd"
service "rsyslog"

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
node.set_unless['openldap']['server']['admin_password'] = secure_password
node.set_unless['openldap']['server']['auth_password'] = secure_password
node.set_unless['openldap']['server']['sync_password'] = secure_password


# Password Checks
#
package "libldap2-dev"
package "dpkg-dev"
package "cracklib-dev"
package "libdb4.6-dev"

execute 'apt-get source slapd' do
  cwd '/tmp'
  not_if {File.exists? "/tmp/openldap-2.4.21"}
end

execute './configure && make' do
  cwd "/tmp/openldap-2.4.21"
  action :nothing
  subscribes :run, resources(:execute => "apt-get source slapd")
end

directory "/etc/openldap" do
  owner "openldap"
  group "openldap"
  mode "0755"
end

remote_directory "/etc/openldap/openldap-ppolicy-check-password" do
  source "openldap-ppolicy-check-password"
  files_owner "root"
  files_group "root"
  files_mode "0755"
  owner "root"
  group "root"
  mode "0755"
  not_if { File.exists?('/etc/openldap/openldap-ppolicy-check-password') }
end

execute "make LIBDIR=/usr/lib/ldap LDAP_INC='-I/tmp/openldap-2.4.21/include/ -I/tmp/openldap-2.4.21/servers/slapd' && cp check_password.so /usr/lib/ldap" do
  cwd "/etc/openldap/openldap-ppolicy-check-password"
  user "root"
  action :nothing
  subscribes :run, resources(:remote_directory => "/etc/openldap/openldap-ppolicy-check-password")
end

template "/etc/openldap/check_password.conf" do
  source "check_password.conf.erb"
  owner "openldap"
  group "openldap"
  mode "0644"
end
# End Password Checks

cookbook_file "/etc/ldap/schema/openssh-lpk_openldap.schema" do
  source "ldap_ssh.schema"
  mode "0644"
end

cookbook_file "/etc/ldap/schema/ldapns.schema" do
  source "ldapns.schema"
  mode "0644"
end

if node[:openldap][:server][:replica]
  # FOR LDAP SERVER DEFINED IN LDAP ROLE
  if node[:openldap][:server][:external_master]
    ldap = node[:openldap][:server][:external_master]
    if ldap[:different_ca_cert]
      cookbook_file "/usr/share/ca-certificates/#{ldap[:fqdn]}.ca.crt" do
        source "#{ldap[:fqdn]}.ca.crt"
        mode "0644"
        owner "openldap"
        group "openldap"
      end
    end

    iptables_rule "output_external_ldap_master" do
      dport 389
      chain 'OUTPUT'
      desination ldap[:ipaddress]
      comment 'Allow access to exteral ldap master'
    end

    iptables_rule "input_external_ldap_master" do
      dport 389
      source ldap[:ipaddress]
      chain 'INPUT'
      comment 'Allow events from external ldap master'
    end
  else
    ldaps = search(:node, "roles:ldap-server") || []
    if ldaps.length > 0
      ldap = ldaps[0]
    end
  end
  node[:openldap][:server][:suffix] = ldap[:openldap][:server][:suffix] if ldap
  node[:openldap][:server][:admin_password] = ldap[:openldap][:server][:admin_password]
  node[:openldap][:server][:auth_password] = ldap[:openldap][:server][:auth_password]
  node[:openldap][:server][:sync_password] = ldap[:openldap][:server][:sync_password]
  node[:openldap][:server][:rid] ||= node[:ipaddress].gsub('.','').to_i % 999
  Chef::Log.info("Ldap server found at #{ldap[:ipaddress]}") if ldap
end

node[:openldap][:server][:server_id] ||= node[:ipaddress].gsub('.','').to_i % 4095

ruby_block "save node data" do
  block do
    node.save
  end
end

template "/etc/ldap/slapd.conf" do
  source "slapd.conf.erb"
  variables :ldap => ldap
end

environments = Chef::Environment.list.keys
template "/etc/ldap/dit.ldif" do
  source "dit.ldif.erb"
  variables :environments => environments
end

#CREATE AN SSL CERTIFICATE
directory "/etc/ldap/ssl" do
  owner "openldap"
  group 'openldap'
  mode "700"
end

ssl_cert node.fqdn do
  destination "/etc/ldap/ssl"
  owner "openldap"
  group "openldap"
end

template "/etc/default/slapd" do
  source "slapd_default.erb"
  mode "0644"
  owner "root"
  group "root"
end

execute "echo 'local4.* #{node[:openldap][:server][:log_file]}' >> /etc/rsyslog.conf" do
  user "root"
  not_if "cat /etc/rsyslog.conf | grep 'local4.* #{node[:openldap][:server][:log_file]}'"
  notifies :restart, resources(:service => 'rsyslog')
end

file node[:openldap][:server][:log_file] do
  mode "0640"
  owner "openldap"
  group "openldap"
  not_if { File.exists?(node[:openldap][:server][:log_file]) }
end

# Logrotate
logrotate_app "ldap" do
  paths node[:openldap][:server][:log_file]
  rotate 4
end

#SETUP LDAP DATABASE
bash "Setup Ldap" do
  user "root"
  code <<-EOH
    /etc/init.d/slapd stop
    rm -rf /var/lib/ldap/*
    rm -rf /etc/ldap/slapd.d/*
    slaptest -f /etc/ldap/slapd.conf -F /etc/ldap/slapd.d
    cp /usr/share/slapd/DB_CONFIG /var/lib/ldap/DB_CONFIG
    sed -i 's/uri=\"\"//g' /etc/ldap/slapd.d/cn=config/olcDatabase\=\{1\}hdb.ldif
    slapadd -v -l /etc/ldap/dit.ldif
    chown -R openldap:openldap /etc/ldap/slapd.d
    chown -R openldap:openldap /var/lib/ldap
    chown -R openldap:openldap /etc/ldap/ssl
  EOH
  not_if { ::File.exists?("/etc/ldap/.ldap_setup") }
end

file "/etc/ldap/.ldap_setup" do
  action :touch
  not_if { File.exists?("/etc/ldap/.ldap_setup") }
end

service "slapd" do
  action [:start, :enable]
end

#Backup
if node.roles.include?("backup") && node[:openldap][:server].include?('backups')
  directory "/tmp/ldap-backups/" do
    owner node[:deploy_user][:user]
    group "root"
    mode "0770"
  end

  # Backup Uploaded Media
  node[:openldap][:server][:backups].each do |backup|
    command_backup "slapcat" do
      command "sudo slapcat -l /tmp/ldap-backups/slapcat.ldif"
      post_command "sudo rm /tmp/ldap-backups/slapcat.ldif"
      paths ["/tmp/ldap-backups/slapcat.ldif"]
      keep backup[:keep]
      every backup[:every]
      at backup[:at]
    end
  end
end

iptables_rule "input_ldap" do
  dport 389
  chain 'INPUT'
  comment "Ldap:// user authentication "
end

iptables_rule "input_ldaps" do
  dport 636
  chain 'INPUT'
  comment "Ldaps:// user authentication"
end
