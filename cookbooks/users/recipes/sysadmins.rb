#
# Cookbook Name:: users
# Recipe:: sysadmins
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
sysadmin_group = Array.new

node.users.each do |username, u|
  sysadmin_group << username

  home_dir = "/home/#{username}"

  user username do
    uid u['uid']
    gid u['gid']
    shell u['shell']
    comment u['comment']
    supports :manage_home => true
    home home_dir
  end

  %w{ bashrc zshrc }.each do |sh|
    template "#{home_dir}/.#{sh}" do
      source "#{sh}.erb"
      owner username
      group u['gid'] || username
    end
  end

  directory "#{home_dir}/.ssh" do
    owner username
    group u['gid'] || username
    mode "0700"
  end

  template "#{home_dir}/.ssh/authorized_keys" do
    source "authorized_keys.erb"
    owner username
    group u['gid'] || username
    mode "0600"
    variables :ssh_keys => u['ssh_keys']
  end
end

group "sysadmin" do
  gid 2300
  members sysadmin_group
end
