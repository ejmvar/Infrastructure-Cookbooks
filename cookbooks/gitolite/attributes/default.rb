default[:gitolite][:repository_url] = "git://github.com/sitaramc/gitolite.git"
default[:gitolite][:host]   = "localhost"
default[:gitolite][:admin_name]   = "git"
default[:gitolite][:ldap] = false
default[:gitolite][:initial_user][:user] = nil
default[:gitolite][:initial_user][:key] = nil

default[:gitolite][:redmine_repo_api_key] = nil

default[:gitolite][:update_redmine] = true
default[:gitolite][:update_jenkins] = true
