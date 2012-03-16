#
# Cookbook Name:: whenever
# Recipe:: default
#
# Copyright 2011, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

node.rails_apps.each do |app_name|

  execute "install CRON tab from whenever" do
    cwd         "/data/#{app_name}/current"
    environment 'RAILS_ENV' => node.rails_app.environment
    command     "bundle exec whenever --update-crontab #{app_name} --set environment=#{node.rails_app.environment}"
    user        "deploy"
    group       "deploy"
  end

end
