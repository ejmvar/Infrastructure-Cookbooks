directory "/home/#{node[:configuration_manager][:user]}/device_configs" do
  owner node[:configuration_manager][:user]
  mode "700"
end

template "/home/#{node[:configuration_manager][:user]}/check_config_changes.sh" do
  source "check_config_changes.sh.erb"
  mode "0700"
  owner node[:configuration_manager][:user]
  group node[:configuration_manager][:user]
end

redmine = search :node, "role:redmine AND role:app_server" || []
unless redmine.empty?
  gem_package 'activeresource' do
    version '3.1.1'
    action :install
  end

  template "/home/#{node[:configuration_manager][:user]}/redmine_alert.rb" do
    source "redmine_alert.rb.erb"
    owner node[:configuration_manager][:user]
    group node[:configuration_manager][:user]
    mode "0700"
    variables :redmine => redmine.first
  end
end

file "/home/#{node[:configuration_manager][:user]}/.config_initialize" do
  owner node[:configuration_manager][:user]
  group node[:configuration_manager][:user]
  mode "0750"
  action :nothing
end

bash "Initialize config tracking" do
  code <<-EOH
    cd /home/#{node[:configuration_manager][:user]}
    ./check_config_changes.sh 'skip_check'
    cd device_configs
    git init
    git commit -m "Initial Commit"
  EOH
  not_if { ::File.exists?("/home/#{node[:configuration_manager][:user]}/.config_initialize") }
  notifies :touch, resources(:file => "/home/#{node[:configuration_manager][:user]}/.config_initialize")
end

directory "/home/#{node[:configuration_manager][:user]}/log" do
  owner node[:configuration_manager][:user]
  group node[:configuration_manager][:user]
  mode "0750"
end

file "/home/#{node[:configuration_manager][:user]}/log/device_config_check.log" do
  owner node[:configuration_manager][:user]
  group node[:configuration_manager][:user]
  mode "750"
  action :touch
end

file "/home/#{node[:configuration_manager][:user]}/log/device_config_check.err" do
  owner node[:configuration_manager][:user]
  group node[:configuration_manager][:user]
  mode "750"
  action :touch
end

cron "check for changes in device configs" do
  hour "1"
  minute "10"
  hour "1"
  command "/home/#{node[:configuration_manager][:user]}/check_config_changes.sh >> /home/#{node[:configuration_manager][:user]}/log/device_config_check.log 2> /home/#{node[:configuration_manager][:user]}/log/device_config_check.err"
  user node[:configuration_manager][:user]
end
