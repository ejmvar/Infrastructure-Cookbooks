#
# Cookbook Name:: splunk
# Recipe:: default
#
# Copyright 2010, VersaPay
#
# All rights reserved - Do Not Redistribute
#

# Install splunk
package "libpcre3-dev"

pkg_arch = nil
short_ver = nil

case node[:kernel][:machine]
when "x86_64"
  pkg_arch = "amd64"
when "i686"
  pkg_arch = "intel"
else
  raise "seems that your system's architecture is neither i686 nor amd64; no dice."
end

short_ver=node[:splunk][:version].match(/\d.\d.\d/).to_s

remote_file node.splunk.package.path do
  source "http://www.splunk.com/index.php/download_track?file=#{short_ver}/splunk/linux/splunk-#{node[:splunk][:version]}-linux-2.6-#{pkg_arch}.deb&ac=wiki_download&wget=true&name=wget&typed=releases"
  action :create_if_missing
end

dpkg_package "splunk" do
  action :install
  source node.splunk.package.path
end

template "/etc/init.d/splunk" do
  source "splunk.init.erb"
  owner "root"
  group "root"
  mode "0755"
end

template "#{node.splunk.install_path}/etc/system/local/user-seed.conf" do
  source "user-seed.conf.erb"
  owner "root"
  group "root"
  mode "0700"
end

service "splunk" do
  supports :start => true, :status => true, :restart => true, :reload => false
  start_command "service splunk start"
  stop_command "service splunk stop"
  restart_command "service splunk restart"
  status_command "service splunk status"
  action [ :start, :enable ]
end

monit_process "splunk" do
  pid_file   node.splunk.pid_path
  executable "/etc/init.d/splunk"
end

directory "#{node[:splunk][:install_path]}/etc/certs" do
  owner "splunk"
  group "splunk"
  mode "0755"
  action :create
end

cookbook_file "#{node[:splunk][:install_path]}/etc/certs/cacert.pem" do
  source "splunk_ca.pem"
  owner "root"
  group "root"
  mode "0644"
end

cookbook_file "#{node[:splunk][:install_path]}/etc/certs/#{node.splunk.web.url}_splunk.pem" do
  source "#{node.splunk.web.url}_splunk.fullcert"
  owner "root"
  group "root"
  mode "0644"
end

# Setup Splunk Inputs
template "#{node.splunk.install_path}/etc/system/local/inputs.conf" do
  source "inputs.conf.erb"
  owner "root"
  group "root"
  mode "0755"
  notifies :restart, resources(:service => 'splunk')
end

#setup Splunk Apps
include_recipe "splunk::install_apps"

#setup ldap authentication
if node.roles.include?("ldap-server")
  ldap = node
else
  ldap = search(:node, "roles:ldap-server")[0]
end


template "#{node[:splunk][:install_path]}/etc/system/local/authentication.conf" do
  source "authentication.conf.erb"
  owner "root"
  group "root"
  mode "0600"
  variables :ldap => ldap
  notifies :restart, resources(:service => 'splunk')
  only_if { ldap }
end

#setup saved searches and alerts
redmine = search :node, "role:redmine AND role:app_server" || []
unless redmine.empty?
  gem_package 'activeresource' do
    version '3.1.1'
    action :install
  end

  template "#{node[:splunk][:install_path]}/bin/scripts/redmine_alert.rb" do
    source "redmine_alert.rb.erb"
    owner "splunk"
    group "splunk"
    mode "0755"
    variables :redmine => redmine.first
  end
end

directory "#{node[:splunk][:install_path]}/etc/apps/search/local" do
  owner "splunk"
  group "splunk"
  mode "0755"
end

template "#{node[:splunk][:install_path]}/etc/apps/search/local/savedsearches.conf" do
  source "savedsearches.search.conf.erb"
  owner "root"
  group "root"
  mode "0600"
  notifies :restart, resources(:service => 'splunk')
end

#setup splunkweb
template "/etc/init.d/splunkweb" do
  source "splunkweb.init.erb"
  owner "root"
  group "root"
  mode "0755"
end

service "splunkweb"

ssl_cert node[:splunk][:web][:url] if node[:splunk][:web][:ssl]

service "splunkweb" do
  supports :start => true, :status => true, :restart => true, :reload => false
  action [ :start ]
end

template "#{node[:splunk][:install_path]}/etc/system/local/web.conf" do
  source "web.conf.erb"
  owner "root"
  group "root"
  mode "0600"
  notifies :restart, resources(:service => 'splunkweb'), :immediately
end

monit_process "splunkweb" do
  pid_file   node.splunk.web.pid_path
  executable "/etc/init.d/splunkweb"
end

# setup splunk license
#cookbook_file "#{node[:splunk][:install_path]}/etc/licenses/enterprise/splunk.license" do
  #source "splunk.license"
  #owner "root"
  #group "root"
  #mode "0600"
  #notifies :restart, resources(:service => 'splunk')
#end

#iptables
iptables_rule "input_splunk_webui" do
  dport 443
  chain 'INPUT'
  comment 'splunk webui'
end

iptables_rule "input_splunk_listener" do
  dport node.splunk.listener.port
  chain 'INPUT'
  comment 'splunk listener for splunkForwarders'
end

iptables_rule "input_splunk_syslog" do
  dport 514
  destination node.ipaddress
  comment "splunk can listen for syslog messages"
  protocol 'udp'
  chain "INPUT"
end
