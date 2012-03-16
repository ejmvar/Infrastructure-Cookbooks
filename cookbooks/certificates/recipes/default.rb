#
# Cookbook Name:: certificate-authority
# Recipe:: default
#
# Copyright 2011, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#

cookbook_file node['certificate-authority']['ca_cert'] do
  source "ca.crt"
  mode "0644"
  owner "root"
  group "root"
end

cookbook_file "/usr/lib/ssl/cert.pem" do
  source "ca.crt"
  mode "0644"
  owner "root"
  group "root"
  not_if { File.exists?("/usr/lib/ssl/cert.pem") }
end
