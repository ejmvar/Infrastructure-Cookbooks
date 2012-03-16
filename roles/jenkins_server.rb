name "jenkins_server"
description "A Continuous integration server for managing the running of test suites"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  "jenkins::server",
  "jenkins::nginx"
])
#default_attributes(
#)
