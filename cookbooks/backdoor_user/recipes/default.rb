#
# Cookbook Name:: backdoor_user
# Recipe:: default
#
# Copyright 2011, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

package 'makepasswd'

u = node[:backdoor_user]

# Chef requires ruby-shadow to compare existing user password
# with the one defined in the recipe. 
if `grep #{u[:username]} /etc/passwd`.empty?
  user u[:username] do
    comment "Backdoor user"
    home "/home/#{u[:username]}"
    password u[:password_shadow_hash]
    shell '/bin/bash'
  end
end

service "ssh" do
  supports :status => true, :restart => true, :reload => false
  action :nothing
end

# bash "ssh - deny backdoor user" do
#   code %{ echo '\nDenyUsers #{u[:username]}' >> /etc/ssh/sshd_config }
#   not_if { File.read('/etc/ssh/sshd_config')[%{DenyUsers #{u[:username]}}] }
#   notifies :restart, resources(:service => 'ssh')
# end
