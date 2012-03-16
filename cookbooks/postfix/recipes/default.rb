#
# Author:: Joshua Timberman(<joshua@opscode.com>)
# Cookbook Name:: postfix
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
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
if node.roles.include?("mail_relay")
  mail_relay = node
else
  mail_relay = search(:node, "roles:mail_relay", nil, 0, 1)[0][0]
end

if mail_relay
  package "postfix" do
    action :install
  end

  service "postfix" do
    action :enable
  end

  %w{main master}.each do |cfg|
    template "/etc/postfix/#{cfg}.cf" do
      source "#{cfg}.cf.erb"
      owner "root"
      group "root"
      mode 0644
      notifies :restart, resources(:service => "postfix")
      variables :mail_relay => mail_relay
    end
  end

  monit_process "postfix" do
    pid_file "/var/spool/postfix/pid/master.pid"
    executable "/etc/init.d/postfix"
  end

  if node.ipaddress == mail_relay.ipaddress
    iptables_rule "input_smtp" do
      source 'internal'
      chain "INPUT"
      dport 25
      comment "Allow incomming smtp for forwarding"
    end

    iptables_rule "output_smtp" do
      chain "OUTPUT"
      dport 25
      comment "Allow smtp output"
    end
  else
    iptables_rule "output_smtp" do
      chain "OUTPUT"
      dport 25
      destination mail_relay.ipaddress
      comment "Allow smtp output to mail relay"
    end
  end
end
