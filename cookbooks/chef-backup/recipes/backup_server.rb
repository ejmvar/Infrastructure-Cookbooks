::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

node.set_unless['backup_server']['encryption_password'] = secure_password

directory node[:backup_server][:backup_dir] do
  owner node[:deploy_user][:user]
  group "root"
  mode "775"
  recursive true
  action :create
end

nodes = search(:node, "role:backup").each do |node|
  ssh_authorization do
    key node[:ssh][:public_key]
  end
end

if node[:backup_server][:external_master]
  iptables_rule "input_external_backup_master" do
    chain "INPUT"
    port 22
    source node[:backup_server][:external_master][:ip_address]
    comment "allow ssh access for external backup master server"
  end

  ssh_authorization do
    key node[:backup_server][:external_master][:key]
  end
end

#Backup
if node.roles.include?("backup") && node.backup_server.include?('backups')
  # Backup Uploaded Media
  node.backup_server.backups.each do |backup|
    file_sync "backups" do
      paths [ "#{node[:backup_server][:backup_dir]}/" ]
      every backup[:every]
    end
  end
end

backup_nodes = search(:node, "role:backup")
backup_nodes = backup_nodes - backup_nodes.collect{|x| x if x.ipaddress == node.ipaddress}
template "/usr/lib/nagios/plugins/check_received_backups.rb" do
  source "check_received_backups.rb.erb"
  owner "nagios"
  group "nagios"
  variables :backup_nodes => backup_nodes
  mode 0755
end
