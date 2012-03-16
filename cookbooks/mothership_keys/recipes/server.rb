package "curl"

directory "/home/#{node[:deploy_user][:user]}/.chef" do
  owner   "#{node[:deploy_user][:user]}"
  group   "#{node[:deploy_user][:user]}"
end


template "/home/#{node[:deploy_user][:user]}/.chef/knife.rb" do
  source  "knife.rb.erb"
  owner   "#{node[:deploy_user][:user]}"
  group   "#{node[:deploy_user][:user]}"
end

gem_package "net-ssh-multi" do
  version '1.1'
end

# Ensure we can read the pem
execute "chmod 644 /etc/chef/client.pem"

template "#{node[:chef_packages][:chef][:chef_root]}/chef/application/knife.rb" do
  source "knife.rb"
  mode 644
end

template "#{node[:chef_packages][:chef][:chef_root]}/chef/knife/ssh.rb" do
  source "ssh.rb"
  mode 644
end

template "/home/#{node[:deploy_user][:user]}/.gitconfig" do
  source "gitconfig.erb"
  owner "#{node[:deploy_user][:user]}"
  group "#{node[:deploy_user][:user]}"
  mode 644
end

iptables_rule "output_mothership_ssh" do
  dport 22
  destination 'internal'
  chain 'OUTPUT'
  comment 'Allow ssh out from mothership to internal servers'
end
