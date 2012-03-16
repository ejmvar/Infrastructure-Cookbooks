unless node[:nginx][:ssl_only]
  iptables_rule "input_http" do
    dport 80
    chain 'INPUT'
    comment 'Allow unsecure http connections for webservice'
    source 'internal' if node[:nginx][:internal_only]
  end
end

iptables_rule "input_https" do
  dport 443
  chain 'INPUT'
  comment 'Allow secure https connections for webservice'
  source 'internal' if node[:nginx][:internal_only]
end

node.rails_apps.each do |rails_app|
  search(:node, "role:app_server AND role:#{rails_app}").each do |app_server|
    iptables_rule "output_https_#{app_server.hostname}" do
      dport 443
      chain 'OUTPUT'
      destination app_server.ipaddress
      comment "Allow secure https connections to application server #{app_server.hostname}"
    end
  end
end
