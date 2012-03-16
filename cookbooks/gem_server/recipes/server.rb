# Used to index empty gem server
package "curl"

execute "curl https://#{node[:fqdn]}/reindex --cacert #{node['certificate-authority']['ca_cert']}" do
  action :nothing
  subscribes :run, resources(:service => "nginx")
end
