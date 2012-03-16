name "jenkins_agent"
description "A continuous integration agent to run application test suites on"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  "jenkins::agent"
])
#default_attributes(
#)
