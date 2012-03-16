default[:splunk][:package][:name] = "splunk-4.2.4-110225-linux-2.6-amd64.deb"
default[:splunk][:package][:path] = "/tmp/#{node.splunk.package.name}"

default[:splunk][:listener][:port] = "9997"
default[:splunk][:forwarder][:ssl_password] = "password"

default[:splunk][:version] = "4.2.4-110225"

# Splunk defaults - Those are Read only
default[:splunk][:install_path] = "/opt/splunk"
default[:splunk][:executable] = "/opt/splunk/bin/splunk"
default[:splunk][:pid_path] = "/opt/splunk/var/run/splunk/splunkd.pid"
default[:splunk][:web][:pid_path] = "/opt/splunk/var/run/splunk/splunkweb.pid"
default[:splunk][:username] = "admin"

#apps
default[:splunk][:apps][:rails][:extracted_name] = "rails"
default[:splunk][:apps][:rails][:package_name] = "splunk-rails-1.01"

default[:splunk][:apps][:license_usage][:extracted_name] = "splunk_license_usage"
default[:splunk][:apps][:license_usage][:package_name] = "splunk-license-usage-2.2"

#configuration
default[:splunk][:ldap][:admin_roles] = ["operations", "developers"]
default[:splunk][:web][:port] = 443
default[:splunk][:web][:ssl] = true
default[:splunk][:web][:url] = node[:fqdn]
default[:splunk][:redmine_api_key] = ''
