
name "mongo_database_master"
description "A mongo db database master"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  'mongodb::10gen_repo',
  'mongodb',
  'rails_app::mongo_database_master'
])
# Attributes applied if the node doesn't have it set already.
#default_attributes()
# Attributes applied no matter what the node has set already.
#override_attributes()

