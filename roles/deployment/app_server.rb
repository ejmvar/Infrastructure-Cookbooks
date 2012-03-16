name "app_server"
description "Should install and run rails app.  This is a server that serves up an application to users"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  'passenger_nginx',
  'rails_app',
  'rails_app::passenger_nginx',
  'mysql::client',
  "role[mail_server]"
])
# Attributes applied if the node doesn't have it set already.
#default_attributes()
# Attributes applied no matter what the node has set already.
#override_attributes()

