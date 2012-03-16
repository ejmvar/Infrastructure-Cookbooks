#
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Joshua Sierles <joshua@37signals.com>
# Cookbook Name:: chef-server
# Recipe:: default
#
# Copyright 2008-2011, Opscode, Inc
# Copyright 2009, 37signals
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

require 'open-uri'

http_request "compact chef couchDB" do
  action :post
  url "#{Chef::Config[:couchdb_url]}/chef/_compact"
  only_if do
    begin
      open("#{Chef::Config[:couchdb_url]}/chef")
      JSON::parse(open("#{Chef::Config[:couchdb_url]}/chef").read)["disk_size"] > 100_000_000
    rescue OpenURI::HTTPError
      nil
    end
  end
end

%w(nodes roles registrations clients data_bags data_bag_items users).each do |view|

  http_request "compact chef couchDB view #{view}" do
    action :post
    url "#{Chef::Config[:couchdb_url]}/chef/_compact/#{view}"
    only_if do
      begin
        open("#{Chef::Config[:couchdb_url]}/chef/_design/#{view}/_info")
        JSON::parse(open("#{Chef::Config[:couchdb_url]}/chef/_design/#{view}/_info").read)["view_index"]["disk_size"] > 100_000_000
      rescue OpenURI::HTTPError
        nil
      end
    end
  end
end

remote_directory "/home/#{node[:ssh][:user]}/.chef/bootstrap" do
  source 'bootstrap'
  owner 'chef'
  group 'chef'
  mode '644'
end

#Backup
if node.roles.include?("backup") && node.chef_server.include?('backups')
  # Backup Uploaded Media
  node.chef_server.backups.each do |backup|
    file_backup "chef" do
      paths ["/var/lib/chef", "/var/lib/couchdb", "/etc/couchdb", "/etc/chef"]
      keep backup[:keep]
      every backup[:every]
      use_sudo true
    end
  end
end

monit_process :chef_server do
  executable "/usr/sbin/service chef-server"
  pid_file "/var/run/chef/server.main.pid"
end

monit_process :chef_webui do
  executable "/usr/sbin/service chef-server-webui"
  pid_file "/var/run/chef/server-webui.main.pid"
end

include_recipe 'chef-server::iptables'
