name "wordpress_server"
description "Runs a wordpress site via apache, mysql and php"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  'wordpress',
  "role[mail_server]"
])
# Attributes applied if the node doesn't have it set already.
#default_attributes()
# Attributes applied no matter what the node has set already.
# override_attributes(
# )
