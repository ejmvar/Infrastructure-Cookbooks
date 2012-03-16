service 'ssh'
# Store an array of hosts
node[:ssh][:authorized_hosts] ||= Array.new

ldaps = search(:node, "recipes:openldap\\:\\:server") || []
ldap = !ldaps.empty? && node[:ssh][:ldap_keys]

if ldap
  cookbook_file "/tmp/openssh-client-lpk.deb" do
    source "openssh-client-lpk.deb"
    action :create_if_missing
  end

  dpkg_package "openssh-client" do
    action :install
    source "/tmp/openssh-client-lpk.deb"
  end

  cookbook_file "/tmp/openssh-server-lpk.deb" do
    source "openssh-server-lpk.deb"
    action :create_if_missing
  end

  dpkg_package "openssh-server" do
    action :install
    source "/tmp/openssh-server-lpk.deb"
  end

  #Pinn the version of ssh
  template "/etc/apt/preferences.d/01ssh" do
    source "ssh_apt_pin.erb"
    owner "root"
    group "root"
    mode "644"
  end
end

directory "/home/#{node[:ssh][:user]}/.ssh" do
  owner "#{node[:ssh][:user]}"
  group "#{node[:ssh][:user]}"
  mode  "0700"
end

# By default, generate an SSH key and store the pub key in node[:public_key]
execute "generate ssh key pair" do
  command "ssh-keygen -f /home/#{node[:ssh][:user]}/.ssh/id_rsa -q -P ''"
  creates "/home/#{node[:ssh][:user]}/.ssh/id_rsa"
  group "#{node[:ssh][:user]}"
  user "#{node[:ssh][:user]}"
  action :run
end

ruby_block "Update SSH Key on Node" do
  block do
    key = File.read("/home/#{node[:ssh][:user]}/.ssh/id_rsa.pub")
	node[:ssh] ||= Mash.new
    if node[:ssh][:public_key] != key
      node[:ssh][:public_key] = key
    end
  end
end

template "/etc/ssh/sshd_config" do
  source "sshd_config.erb"
  owner 'root'
  group 'root'
  mode 644
  # variables(:users => node[:users].keys | [ node[:deploy_user][:user] ] )
  variables(:ldap => ldap)
  notifies :restart, resources(:service => 'ssh'), :immediately
end
