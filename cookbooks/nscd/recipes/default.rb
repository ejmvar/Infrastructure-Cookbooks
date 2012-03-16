#
# Cookbook Name:: nscd
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
package "nscd" do
  action :upgrade
end

service "nscd" do
  supports :restart => true, :status => true
  action [:enable, :start]
end

%w{ passwd group }.each do |cmd| 
  execute "nscd-clear-#{cmd}" do
    command "/usr/sbin/nscd -i #{cmd}"
    action :nothing
  end
end

monit_process "nscd" do
  pid_file "/var/run/nscd/nscd.pid"
  executable "/etc/init.d/nscd"
end

file "/var/log/restart_nscd.log" do
  owner "root"
  group "root"
  mode "755"
  action :touch
end

file "/var/log/restart_nscd.err" do
  owner "root"
  group "root"
  mode "755"
  action :touch
end

cron "restart nscd" do
  hour "1"
  minute "0"
  command "(service nscd stop && service nscd start) >> /var/log/restart_nscd.log 2> /var/log/restart_nscd.err"
end
