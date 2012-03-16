#
# Cookbook Name:: nginx
# Recipe:: install_packages_and_extract_sources
#
# Install required packages and extract nginx source
#
# Copyright 2010, VersaPay
#
# All rights reserved - Do Not Redistribute
#

#include_recipe 'iptables'

# the following package might be required by nginx too: libgcrypt11-dev libssl-dev
%w(build-essential libcurl4-openssl-dev libpcre3-dev).each do |pkg|
  package pkg
end

cookbook_file "/tmp/nginx-#{node[:nginx][:version]}.tar.gz" do
  source "nginx-#{node[:nginx][:version]}.tar.gz"
  action :create_if_missing
end

bash "extract nginx source" do
  cwd "/tmp"
  code "tar zxf nginx-#{node[:nginx][:version]}.tar.gz"
  not_if { File.directory?("/tmp/nginx-#{node[:nginx][:version]}") }
end

