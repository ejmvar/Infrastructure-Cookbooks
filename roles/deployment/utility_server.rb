name "utility_server"
description "An application utility server. Includes app code but no web server(does not serve pages to users), The utility server runds delayed jobs from an application"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  'rails_app',
  'rails_app::delayed_job',
  'mysql::client',
  "role[mail_server]"
])
# Attributes applied if the node doesn't have it set already.
#default_attributes()
# Attributes applied no matter what the node has set already.
#override_attributes()

