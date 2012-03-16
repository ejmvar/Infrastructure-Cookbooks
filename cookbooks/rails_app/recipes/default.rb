#
# Cookbook Name:: rails_app
# Recipe:: default
#
# Copyright 2010, VersaPay
#
# All rights reserved - Do Not Redistribute
#

include_recipe "ssh"

# Let's deploy each rails app registered to this node
node.rails_apps.each do |app_name|
  node.run_state[:app_name] = app_name

  # Force include
  node.run_state[:seen_recipes].delete("rails_app::deploy")
  include_recipe "rails_app::deploy"
end

node.run_state.delete(:app_name)
