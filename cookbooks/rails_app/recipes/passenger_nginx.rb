node.rails_apps.each do |app_name|
  template "#{node[:nginx][:conf_dir]}/sites-available/#{app_name}" do
    source "passenger_nginx.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
      :app => app_name,
      :rails_env => node.rails_app.environment,
      :docroot => "#{node.rails_app.deploy_dir}/#{app_name}/current/public",
      :fqdn => node.fqdn,
      :rails_env => node.rails_app.environment
    )
    notifies :restart, resources(:service => "nginx")
  end

  ssl_cert node.fqdn

  nginx_site app_name
end

unless node[:nginx][:ssl_only]
  iptables_rule "input_http" do
    dport 80
    chain 'INPUT'
    comment 'Allow unsecure http connections for webservice'
    source = 'internal' if node[:nginx][:internal_only]
  end
end

iptables_rule "input_https" do
  dport 443
  chain 'INPUT'
  comment 'Allow secure https connections for webservice'
  source = 'internal' if node[:nginx][:internal_only]
end
