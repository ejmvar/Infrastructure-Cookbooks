name "base"
description "Base role applied to all nodes.  Sets up server to fetch packages and gems form local apt proxy, gem proxy, and gem server.  Configures authentication and permissions to use ldap with the local ldap server.  Sets up server to resolve dns using local dns servers.  Sets up access for the local mothership server to allow mothership to manage deployment on this server.  Installs and configures ntp for time syncronization.  Configures the server to use and trust the chef generated certificate authority.  Configures the server to log to splunk and report problems to nagios.  Sets up a backdoor user in case of access failure.  Configures monit to monitor status of essential services. Sets up iptables on the server to restrict unwanted connections."
run_list([
  "chef-backup::reset_backup_jobs",
  "apt",
  "gem_server::client",
  "bind",
  "iptables",
  "certificates",
  "chef-client::delete_validation",
  "chef-client::config",
  "monit",
  "openldap",
  "backdoor_user",
  'sudo',
  'ssh',
  "mothership_keys::client",
  "ntp",
  "splunk",
  "nagios::client",
  "deploy_user",
  "iptables::activate"
])

# Attributes applied if the node doesn't have it set already.
default_attributes({
  :force_deploy => false,
  :ssh => { :ldap_keys => true },
  :datacenter => "0"
  # uncomment to enable iptables
  # :iptables => { :reject_input => true, :reject_output => true }
})
override_attributes({
  :ntp => { :servers => ['0.pool.ntp.org' , '1.pool.ntp.org'] }
})
