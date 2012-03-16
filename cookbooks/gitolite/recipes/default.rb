#
# Cookbook Name:: gitolite
# Recipe:: default
#
# Copyright 2010, RailsAnt, Inc.
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
# 
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "git::default"

node.set_unless['gitolite']['password'] = secure_password
user "git" do
  comment "Git User"
  home "/home/git"
  shell "/bin/bash"
end

directory "/home/git" do
  owner "git"
  group "git"
  mode "0755"
end

gem_package "httparty"

if node.gitolite.deploy_key
  deploy_key_path = '/home/git/deploy_key'

  ruby_block "write_key" do
    block do
      File.open(deploy_key_path, "w") do |f|
        f.print(node['gitolite']["deploy_key"])
      end
    end
    # always overwrite the deploy_key with the one from the databag
  end

  # Make the deploy_key readable by owner only
  file deploy_key_path do
    owner 'git'
    group 'git'
    mode '0600'
  end

  template "/home/git/deploy-ssh-wrapper" do
    source "deploy-ssh-wrapper.erb"
    owner 'git'
    group 'git'
    mode "0755"
    variables(:id => 'gitolite', :deploy_key_path => deploy_key_path)
    not_if { File.exists?("/home/git/deploy-ssh-wrapper") }
  end
end

git "/home/git/gitolite" do
  repository node[:gitolite][:repository_url]
  reference "master"
  action :sync
  user "git"
  ssh_wrapper "/home/git/deploy-ssh-wrapper" if node['gitolite']['deploy_key']
end

execute "ssh-keygen -q -f /home/git/.ssh/id_rsa -N \"\" " do
  user "git"
  action :run
  not_if {File.exist? '/home/git/.ssh/id_rsa.pub'}
end

execute "cp /home/git/.ssh/id_rsa.pub /home/git/.ssh/authorized_keys" do
  user "git"
  not_if {File.exist? '/home/git/.ssh/authorized_keys'}
end

execute "export PATH=/home/git/bin:$PATH && src/gl-system-install" do
  user "git"
  environment ({'HOME' => '/home/git'})
  cwd "/home/git/gitolite"
  not_if { File.exists?("/home/git/repositories") }
end

if node.run_list.include?("roles:ldap-server")
  ldap = node
else
  ldaps = search(:node, "roles:ldap-server") || []
  ldap = ldaps ? ldaps.first : false
end

template "/home/git/bin/expand-ldap-user-to-groups" do
  source "ldap-search.sh.erb"
  owner "git"
  group "git"
  mode "0700"
  variables :ldap => ldap
  only_if { ldap && node[:gitolite][:ldap] }
end

template "/home/git/.gitolite.rc" do
  source "gitolite.rc.erb"
  owner "git"
  group "git"
  mode "0700"
  variables :ldap => ldap
end

if node[:gitolite][:initial_user][:user] && node[:gitolite][:initial_user][:key]
  execute "save git admin key" do
    user "git"
    cwd "/tmp"
    command "echo '#{node[:gitolite][:initial_user][:key]}' > #{node[:gitolite][:initial_user][:user]}.pub"
    not_if { File.exists? "/tmp/#{node[:gitolite][:initial_user][:user]}.pub" }
  end

  execute "setup initial git admin" do
    user "git"
    environment ({'HOME' => '/home/git'})
    cwd "/home/git"
    command "export PATH=/home/git/bin:$PATH && gl-setup /tmp/#{node[:gitolite][:initial_user][:user]}.pub"
    subscribes :run, resources(:execute => "save git admin key"), :immediately
    action :nothing
  end
end

execute "setup git hooks" do
  command "export PATH=/home/git/bin:$PATH && gl-setup"
  environment ({'HOME' => '/home/git'})
  user "git"
  cwd "/home/git"
  return [0,1]
  action :nothing
end

redmine = search(:node, "roles:redmine AND roles:app_server", nil, 0, 1)[0][0]
if redmine && node[:gitolite][:redmine_repo_api_key]
  template "/home/git/share/gitolite/hooks/common/post-receive" do
    source "ci-push.rb.erb"
    owner "git"
    group "root"
    mode "0755"
    variables :redmine => redmine
    notifies :run, resources(:execute => "setup git hooks")
  end
end

jenkins_server = search(:node, "roles:jenkins_server", nil, 0, 1)[0][0]
template "/home/git/share/gitolite/hooks/common/post-receive" do
  source "ci-push.rb.erb"
  owner "git"
  group "root"
  mode "0755"
  variables :redmine => redmine, :jenkins_server => jenkins_server
  notifies :run, resources(:execute => "setup git hooks")
end
