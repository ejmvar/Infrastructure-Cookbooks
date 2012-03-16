# setup administrator user password
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

node.set_unless['splunk']['password'] = secure_password

ruby_block "save node data" do
  block do
    node.save
  end
  action :create
end

unless node.run_list.roles.include? 'splunk_server'
  include_recipe 'splunk::forwarder'
end
