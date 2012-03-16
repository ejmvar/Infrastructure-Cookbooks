name "proxy"
description "Setup a reverse proxy for an application (SSL powered) and load balance between application servers"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  'proxy_nginx',
])
