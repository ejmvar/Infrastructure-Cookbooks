#
# Cookbook Name:: deploy_user
# Recipe:: default
#
# Copyright 2010, VersaPay Corporation
#
# All rights reserved - Do Not Redistribute
#


# Updates the deploy user's password to a random 20 digit password.
bash "update #{node[:deploy_user][:user]} user password" do
  new_password = ""
  new_password << ::OpenSSL::Random.random_bytes(1).gsub(/\W/, '') while new_password.length < 20

  code "echo -e '#{new_password}\n#{new_password}' | passwd #{node[:deploy_user][:user]} && touch /home/#{node[:deploy_user][:user]}/.user-updated"
  not_if "test -f /home/#{node[:deploy_user][:user]}/.user-updated"
  user "root" #node[:deploy_user][:user]
end
