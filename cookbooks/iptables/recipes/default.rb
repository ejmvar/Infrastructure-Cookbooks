#
# Cookbook Name:: iptables
# Recipe:: default
#
# Copyright 2008-2009, Opscode, Inc.
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

package "iptables" 

execute "restore-iptables" do
  command "/sbin/iptables-restore < /etc/iptables/general"
  action :nothing
end

execute "rebuild-iptables" do
  command "/usr/sbin/rebuild-iptables"
  action :nothing
  notifies :run, resources(:execute => "restore-iptables")
end

directory "/etc/iptables.d" do
  action :create
end

cookbook_file "/usr/sbin/rebuild-iptables" do
  source "rebuild-iptables"
  mode 0755
  action :create_if_missing
end

iptables_rule_from_template "all_established"
iptables_rule_from_template "input_icmp"
iptables_rule_from_template "input_igmp"

iptables_rule "input_ssh" do
  dport 22
  source 'internal'
  chain 'INPUT'
  comment 'Allow deployment server to trigger chef run'
end

iptables_rule "input_dhcp_client" do
  dport     67
  protocol  'udp'
  chain     'INPUT'
  comment   "Allow dhcp client"
end

search(:node, "role:git-server").each do |git_server|
  iptables_rule "output_ssh_git_server_#{git_server.hostname}" do
    dport 22
    chain 'OUTPUT'
    destination git_server.ipaddress
    comment "Allow ssh output access to git server to pull repos:#{git_server.hostname}"
  end
end
