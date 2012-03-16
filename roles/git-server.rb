name "git-server"
description "A gitolite server for storing and accessing all git repositories"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  'gitolite'
])
# Attributes applied if the node doesn't have it set already.
default_attributes(
  :gitolite => {
    :ldap => true,
    :repository_url => 'git://github.com/sitaramc/gitolite.git',
    :initial_user => {
      :user =>"userid",
      :key => "user ssh public key"
    },
    :redmine_repo_api_key => "",
    :update_redmine => false,
    :update_jenkins => false
  }
)
# Attributes applied no matter what the node has set already.
#override_attributes()

