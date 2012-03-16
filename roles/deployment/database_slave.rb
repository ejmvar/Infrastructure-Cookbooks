name "database_slave"
description "The mysql database slave role"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  'mysql::slave'
#  'backup'
])

