iptables_rule "output_gemproxy_http" do
  dport     80
  chain     'OUTPUT'
  comment   "Output gemproxy collector"
end
