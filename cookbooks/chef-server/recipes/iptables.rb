include_recipe "iptables"

iptables_rule "input_https" do
  dport 443
  chain 'INPUT'
  comment 'chef-server: allow https access for chef-client'
end

iptables_rule "input_https_web_server" do
  dport 444
  chain 'INPUT'
  comment 'chef-server: allow https access to chef-webui'
end

# iptables_rule "input_chef_server_api" do
#   dport 4000
#   chain 'INPUT'
#   comment 'chef-server: allow knife to connect'
# end


# iptables_rule "input_chef_server_webui" do
#   dport 4040
#   chain 'INPUT'
#   comment 'chef-server: webui'
# end
