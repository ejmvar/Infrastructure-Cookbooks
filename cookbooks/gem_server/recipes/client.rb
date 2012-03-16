gem_servers = search(:node, "role:gem_server AND role:app_server") || []
gem_proxies = search(:node, "roles:gem_proxy AND role:app_server") || []

unless gem_servers.empty? && gem_proxies.empty?
  gem_servers.each do |gem_server|
    iptables_rule "output_gem_server_#{gem_server.hostname}" do
      dport 443
      chain 'OUTPUT'
      destination gem_server.ipaddress
      comment "Retrieve gems from gem-server #{gem_server.hostname}"
    end
 end

  gem_proxies.each do |gem_proxy|
    iptables_rule "output_gem_proxy_#{gem_proxy.hostname}" do
      dport 443
      chain 'OUTPUT'
      destination gem_proxy.ipaddress
      comment "Retrieve gems from gem-proxy #{gem_proxy.hostname}"
    end
  end

  template "/etc/gemrc" do
    source "gemrc.erb"
    owner 'root'
    group 'root'
    mode "0644"
    variables :gem_servers => gem_servers, :gem_proxies => gem_proxies
  end
end
