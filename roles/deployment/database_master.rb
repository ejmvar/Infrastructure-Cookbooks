
name "database_master"
description "The mysql database master server"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  'mysql::server',
  'rails_app::database_master'
])
# Attributes applied if the node doesn't have it set already.
#default_attributes()
# Attributes applied no matter what the node has set already.
#override_attributes()

