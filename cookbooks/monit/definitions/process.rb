# /etc/init.d/* scripts always have to be run as 'root'. These scripts take care of
# launching processes with the right user (www-data, aptproxy, nagios ...)
define :monit_process, :pid_file => nil, :executable => nil, :user => 'root', :group => nil do
  execute "monit_reload" do
    command "/usr/sbin/monit reload"
  end

  template "/etc/monit/conf.d/#{params[:name]}.monitrc" do
    source "monit_process.monitrc.erb"
    cookbook "monit"
    variables(params)
    notifies :run, resources(:execute => "monit_reload")
  end
end
