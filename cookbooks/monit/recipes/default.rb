package "monit" do
  action :install
end

if node[:monit][:ssl]
  directory "/etc/monit/ssl"

  template "/etc/monit/ssl/monit.cnf" do
    source "monit.cnf.erb"
    variables :fqdn => node[:fqdn]
    owner "root"
    group "root"
  end

  bash "gereate monit ssl cert" do
    user "root"
    code <<-EOH
      /usr/bin/openssl req -new -x509 -days 3650 -nodes -config monit.cnf -out /etc/monit/ssl/monit.pem -keyout /etc/monit/ssl/monit.pem -batch
      /usr/bin/openssl gendh 512 >> /etc/monit/ssl/monit.pem
      chmod 700 /etc/monit/ssl/monit.pem
    EOH
    cwd "/etc/monit/ssl"
    not_if {::File.exists?("/etc/monit/ssl/monit.pem")}
  end
end

cookbook_file "/etc/default/monit" do
  source "monit.default"
  owner "root"
  group "root"
  mode 0644
end

service "monit" do
  action :start
  enabled true
  supports [:start, :restart, :stop]
end

iptables_rule "input_monit" do
  dport 3737
  chain 'INPUT'
  comment 'Allow nagios to access monit webui'
end

template "/etc/monit/monitrc" do
  owner "root"
  group "root"
  mode 0700
  source 'monitrc.erb'
  notifies :restart, resources(:service => "monit"), :immediate
end

execute "monit_reload" do
  command "/usr/sbin/monit reload"
end

# Create a directory for all monit processes to log to
directory "/var/log/monit" do
  mode "777"
end
