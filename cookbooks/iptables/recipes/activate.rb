template "/usr/sbin/rebuild-iptables" do
  source "rebuild-iptables.erb"
  mode 0755
  notifies :run, resources(:execute => 'rebuild-iptables')
end
