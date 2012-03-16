
define :iptables_rule, :enable => true, 
  :chain => nil, :port => nil, :protocol => 'tcp',
  :source => nil, :destination => nil, :comment => '' do

  params[:source] = node[:iptables][:internal_range] if params[:source] == 'internal'
  params[:destination] = node[:iptables][:internal_range] if params[:destination] == 'internal'

  include_recipe "iptables"
  template "/etc/iptables.d/#{params[:name]}" do
    source "rule_accept.erb"
    cookbook "iptables"
    mode 0644
    variables params
    backup false
    notifies :run, resources(:execute => "rebuild-iptables"), :immediately
    if params[:enable]
      action :create
    else
      action :delete
    end
  end

end

