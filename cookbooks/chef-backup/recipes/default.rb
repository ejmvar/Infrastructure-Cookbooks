#
# Cookbook Name:: backup
# Recipe:: default
#
# Copyright 2011, Alastair Brunton
#
# MIT license
#

# Install backup, s3sync, fog, mail, whenever

backup = node.run_list.include?("role:backup_server") ? node : search(:node, "roles:backup_server", nil, 0, 1)[0][0]
#include_recipe "postfix" if node[:backup][:mail][:on_success] || node[:backup][:mail][:on_failure]

if backup
  package "libxslt" do
    package_name "libxslt-dev"
    action :install
  end

  package "libxml-dev" do
    package_name "libxml2-dev"
    action :install
  end

  {'backup' => '3.0.19', 'i18n' => '0.6.0', 'net-scp' => '1.0.4', 's3sync' => '1.2.5', 'whenever' => '0.7.0', 'choice' => '0.1.4' }.each do |gem_name, gem_version|
    gem_package gem_name do
      action :install
      version gem_version
    end
  end

  ['Backup', 'Backup/config', 'Backup/log'].each do |dir|
    execute "mkdir /home/#{node[:deploy_user][:user]}/#{dir}" do
      user node[:deploy_user][:user]
      only_if { !File.directory?("/home/#{node[:deploy_user][:user]}/#{dir}") }
    end
  end


  template "/home/#{node[:deploy_user][:user]}/Backup/config.rb" do
    owner node[:deploy_user][:user]
    source "config.rb.erb"
    variables(:backup => backup)
  end

  execute "update backup schedule" do
    command "whenever --update-crontab"
    cwd "/home/#{node[:deploy_user][:user]}/Backup"
    user node[:deploy_user][:user]
    action :nothing
  end

  # Whenever config setup.
  template "/home/#{node[:deploy_user][:user]}/Backup/config/schedule.rb" do
    owner node[:deploy_user][:user]
    source "schedule.rb.erb"
    variables(:config => node[:backup])
    notifies :run, resources(:execute => "update backup schedule"), :immediately
  end

  template "/etc/logrotate.d/whenever_log" do
    owner "root"
    source "logrotate.erb"
    variables(:backup_path => "/home/#{node[:deploy_user][:user]}/Backup")
  end

  template "/home/#{node[:deploy_user][:user]}/Backup/initial_backup.sh" do
    source "initial_backup.sh.erb"
    owner node[:deploy_user][:user]
    mode 0770
  end

  template "/usr/lib/nagios/plugins/check_backups.rb" do
    source "check_backups.rb.erb"
    owner "nagios"
    group "nagios"
    mode 0755
  end

  iptables_rule "output_backups_to_backup_server" do
    chain "OUTPUT"
    dport 22
    destination backup.ipaddress
    comment "Allow ssh access to backup server for dumping backups"
  end
end
