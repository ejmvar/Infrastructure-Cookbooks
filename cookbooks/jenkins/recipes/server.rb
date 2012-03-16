include_recipe "jenkins::default"

include_recipe "apt"
# apt_repository "jenkins" do
#   uri "http://pkg.jenkins-ci.org/debian"
#   key "http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key"
#   components ["binary/"]
#   action :add
# end

# package "jenkins"
#
package "daemon"

remote_file "/tmp/jenkins_1.448_all.deb" do
  source "http://pkg.jenkins-ci.org/debian/binary/jenkins_1.448_all.deb"
  action :create_if_missing
end

dpkg_package "jenkins" do
  action :install
  source "/tmp/jenkins_1.448_all.deb"
end

service "jenkins" do
  supports [:status, :restart, :start, :stop]
  status_command "/etc/init.d/jenkins status | grep 'Jenkins is running'"
  action [:start, :enable]
end

jenkins_plugin node[:jenkins][:plugins]

# Generate ssh keypair for user jenkins
# This is extracted from recipe 'ssh'
# Jenkins will connect to agents using this key pair
# Server and Agents will grab the code from github using this key pair
# By default, generate an SSH key and store the pub key in node[:public_key]
execute "generate ssh key pair" do
  command "ssh-keygen -f /home/jenkins/.ssh/id_rsa -q -P ''"
  creates "/home/jenkins/.ssh/id_rsa"
  group "jenkins"
  user "jenkins"
  action :run
end

ruby_block "Update SSH Key on Node" do
  block do
    key = File.read("/home/jenkins/.ssh/id_rsa.pub")
	node[:ssh] ||= Mash.new

    if node[:ssh][:public_key] != key
      node[:ssh][:public_key] = key
    end

    node[:jenkins][:deploy_public_key] = key
    private_key = File.read("/home/jenkins/.ssh/id_rsa")
    node[:jenkins][:deploy_private_key] = private_key
  end
end

iptables_rule "output_ssh_jenkins" do
  dport 22
  destination 'internal'
  chain 'OUTPUT'
  comment 'allow jenkins to execute ssh commands'
end
