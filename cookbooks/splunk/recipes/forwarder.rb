#
# Cookbook Name:: splunk
# Recipe:: default
#
# Copyright 2010, VersaPay
#
# All rights reserved - Do Not Redistribute
#
#
#Set and save the splunk admin password
#
splunk_servers = search(:node, 'role:splunk_server') || []
unless splunk_servers.empty?

  pkg_arch = nil
  short_ver = nil

  case node[:kernel][:machine]
  when "x86_64"
    pkg_arch = "amd64"
  when "i686"
    pkg_arch = "intel"
  else
    raise "seems that your system's architecture is neither i686 nor amd64; no dice."
  end

  short_ver=node[:splunk][:forwarder][:version].match(/\d.\d.\d/).to_s

  remote_file node.splunk.forwarder.package.path do
    source "http://www.splunk.com/index.php/download_track?file=#{short_ver}/universalforwarder/linux/splunkforwarder-#{node[:splunk][:forwarder][:version]}-linux-2.6-#{pkg_arch}.deb&ac=wiki_download&wget=true&name=wget&typed=releases"
    action :create_if_missing
  end

  dpkg_package "splunkforwarder" do
    action :install
    source node.splunk.forwarder.package.path
  end

  template "/etc/init.d/splunkforwarder" do
    source "splunkforwarder.init.erb"
    owner "root"
    group "root"
    mode "0755"
  end

  template "#{node.splunk.forwarder.install_path}/etc/system/local/user-seed.conf" do
    source "user-seed.conf.erb"
    owner "root"
    group "root"
    mode "0700"
  end

  service "splunkforwarder" do
    supports :start => true, :status => true, :restart => true, :reload => false
    start_command "service splunkforwarder start"
    stop_command "service splunkforwarder stop"
    restart_command "service splunkforwarder restart"
    status_command "service splunkforwarder status"
    action [ :start, :enable ]
  end

  monit_process "splunk" do
    pid_file   node.splunk.forwarder.pid_path
    executable "/etc/init.d/splunkforwarder"
  end

  # Setup Splunk Inputs
  template "#{node.splunk.forwarder.install_path}/etc/system/local/inputs.conf" do
    source "inputs.conf.erb"
    owner "root"
    group "root"
    mode "0755"
    notifies :restart, resources(:service => 'splunkforwarder')
  end

  directory "#{node[:splunk][:forwarder][:install_path]}/etc/certs" do
    owner "splunk"
    group "splunk"
    mode "0755"
    action :create
  end

  cookbook_file "#{node[:splunk][:forwarder][:install_path]}/etc/certs/cacert.pem" do
    source "splunk_ca.pem"
    owner "root"
    group "root"
    mode "0644"
  end

  splunk_servers.each do |splunk_server|
    cookbook_file "#{node[:splunk][:forwarder][:install_path]}/etc/certs/#{splunk_server.splunk.web.url}_splunk.pem" do
      source "#{splunk_server.splunk.web.url}_splunk.fullcert"
      owner "root"
      group "root"
      mode "0644"
    end

    iptables_rule "output_splunk_#{splunk_server.hostname}" do
      dport splunk_server.splunk.listener.port
      chain 'OUTPUT'
      destination splunk_server.ipaddress
      comment "Send logs to splunk server #{splunk_server.hostname}"
    end
  end

  # Setup Splunk Outputs
  template "#{node.splunk.forwarder.install_path}/etc/system/local/outputs.conf" do
    source "outputs.conf.erb"
    owner "root"
    group "root"
    mode "0755"
    variables :splunk_servers => splunk_servers
    notifies :restart, resources(:service => 'splunkforwarder')
  end
end
