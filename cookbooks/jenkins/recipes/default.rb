package 'slapd'
package 'ldap-utils'

service "slapd" do
  action :stop
end

link "/etc/openldap" do
  to "/etc/ldap"
end

user "jenkins" do
  home "/home/jenkins"
  shell "/bin/bash"
end

directory "/var/lib/jenkins" do
  recursive true
  owner "jenkins"
  mode 0700
end

directory "/home/jenkins" do
  recursive true
  owner "jenkins"
  mode 0700
end

directory "/home/jenkins/.ssh" do
  owner "jenkins"
  group "jenkins"
  mode  "0700"
end


link "/home/jenkins/lib" do
  to "/var/lib/jenkins"
end

# git requires that a user be set to checkout...
template "/home/jenkins/.gitconfig" do
  owner "jenkins"
  source "dot.gitconfig.erb"
  only_if "which git"
end

# git requires that a user be set to checkout...
template "/home/jenkins/.bashrc" do
  owner "jenkins"
  source "dot.bashrc.erb"
end

node[:authorization][:sudo][:groups] << 'jenkins'
node[:authorization][:sudo][:users] << 'jenkins'

include_recipe "jenkins::headless"
include_recipe "java"
