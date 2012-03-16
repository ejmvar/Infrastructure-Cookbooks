# Example to setup a tunnel:
#
# ssh_tunnel "eft3" do
#   port 4406
#   host 'localhost'
#   host_port 3306
#   user 'deploy'
# end

define :ssh_tunnel, :action => :enable, 
					:host => nil,
					:host_port => 3306,
					:ssh_user => nil,
					:local_port => 4406,
					:description => "SSH Tunnel" do

  params[:ssh_user] ||= node[:ssh][:user]
  tunnel_name = params[:name]
  exec_name = "/etc/init.d/#{tunnel_name}"

  template exec_name do
    source "tunnel-init.sh.erb"
    cookbook "ssh"
    owner 'root'
    group 'root'
    mode '0755'
    variables params
  end

  monit_process tunnel_name do
    executable exec_name
    pid_file   "/var/run/#{tunnel_name}.pid"
  end
end
