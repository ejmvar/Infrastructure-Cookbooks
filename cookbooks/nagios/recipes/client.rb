#
# Author:: Joshua Sierles <joshua@37signals.com>
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: nagios
# Recipe:: client
#
# Copyright 2009, 37signals
# Copyright 2009-2010, Opscode, Inc
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
mon_host = Array.new

if node.roles.include?(node[:nagios][:server_role])
  mon_host << node[:ipaddress]
else
  search(:node, "roles:#{node[:nagios][:server_role]}") do |n|
    mon_host << n['ipaddress']
  end
end

# Do nothing unless we have a monitoring host
if mon_host.any?
  %w{
    nagios-nrpe-server
    nagios-plugins
    nagios-plugins-basic
    nagios-plugins-standard
  }.each do |pkg|
    package pkg
  end

  service "nagios-nrpe-server" do
    action :enable
    supports :restart => true, :reload => true
  end

  %w{
    check_mem.sh
    check_monit.py
    check_mysql_backups.rb
    check-mysql-slave.pl
    kinda_check_apt
    check_rabbitmq_aliveness
    check_rabbitmq_objects
    check_rabbitmq_overview
    check_rabbitmq_server
  }.each do |plugin|
    cookbook_file "/usr/lib/nagios/plugins/#{plugin}" do
      source "plugins/#{plugin}"
      owner "nagios"
      group "nagios"
      mode 0755
      # I don't think that we need to restart nagios-nrpe when adding a new script.
      # Nagios nrpe does not cache these scripts
      #notifies :restart, resources(:service => "nagios-nrpe-server")
    end
  end

  if node.roles.include?('chef_server')
    chef_server = node
  else
    chef_server = search(:node, "roles:chef_server").first
  end

  if node.roles.include?("ldap-server")
    ldap = node
  else
    ldap = search(:node, "roles:ldap-server", nil, 0, 1)[0][0]
  end

  git_server = search(:node, "roles:git-server", nil, 0, 1)[0][0]

  errbit_server = search(:node, "role:errbit AND role:app_server", nil, 0, 1)[0][0]

  template "/etc/nagios/nrpe.cfg" do
    source "nrpe.cfg.erb"
    owner "nagios"
    group "nagios"
    mode "0644"
    variables :mon_host => mon_host, :chef_server => chef_server, :ldap => ldap, :git_server => git_server, :splunk_server => search(:node, "roles:splunk_server", nil, 0, 1)[0][0], :errbit_server => errbit_server
    # Force a restart so that if we crash, at least nagios is working
    notifies :restart, resources(:service => "nagios-nrpe-server"), :immediately
  end

  # Kill nrpe if it's out of sync with its pid file
  execute "killall nrpe || echo 'No nrpe to kill'" do
    not_if "ps -p `cat /var/run/nagios/nrpe.pid`"
  end

  monit_process "nagios-nrpe-server" do
    pid_file "/var/run/nagios/nrpe.pid"
    executable "/etc/init.d/nagios-nrpe-server"
  end

  package 'curl'
  node[:nagios][:new_services].each do |new_service|

    ruby_block "remove #{new_service} from new services" do
      block do
        node[:nagios][:new_services] = node[:nagios][:new_services] - [ new_service ]
      end
      action :nothing
    end

    mon_host.each do |monitor|
      execute "enable active checks of new service #{new_service}" do
        command "curl -d 'cmd_typ=5&host=#{node[:fqdn]}&service=#{new_service.gsub(' ','+')}&cmd_mod=2' 'http://#{monitor}/cgi-bin/nagios3/cmd.cgi' -u 'admin:Monvpy1500'"
      end

      execute "enable passive checks of new service #{new_service}" do
        command "curl -d 'cmd_typ=39&host=#{node[:fqdn]}&service=#{new_service.gsub(' ','+')}&cmd_mod=2' 'http://#{monitor}/cgi-bin/nagios3/cmd.cgi' -u 'admin:Monvpy1500'"
        notifies :create, resources(:ruby_block => "remove #{new_service} from new services")
      end
    end
  end

  iptables_rule "input_nagios_nrpe" do
    dport 5666
    chain 'INPUT'
    comment 'Allow nagios to execute remote monitoring via NRPE'
  end

  # Save the fact that this node is now monitored
  node[:nagios][:monitored] = true
  node.save
else
  Chef::Log.info "No nagios server found. Not installing nagios nrpe."
end
