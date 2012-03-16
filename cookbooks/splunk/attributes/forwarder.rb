default[:splunk][:forwarder][:package][:name] = "splunkforwarder-4.2.4-110225-linux-2.6-amd64.deb"
default[:splunk][:forwarder][:package][:path] = "/tmp/#{node.splunk.forwarder.package.name}"

default[:splunk][:forwarder][:version] = "4.2.4-110225"

# Splunk defaults - Those are Read only
default[:splunk][:forwarder][:install_path] = "/opt/splunkforwarder"
default[:splunk][:forwarder][:executable] = "/opt/splunkforwarder/bin/splunk"
default[:splunk][:forwarder][:pid_path] = "/opt/splunkforwarder/var/run/splunk/splunkd.pid"
