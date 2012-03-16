name "mothership"
description "Mothership role applied to server dealing with mothership. Mothership is a command center for executing deployments and repeated jobs accross the environment"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
   "mothership_keys::server"
])
# Attributes applied if the node doesn't have it set already.
default_attributes(
  
  # Register mothership to the set of rails_apps.
  "rails_apps" => ["mothership"],

  
  # mothership attributes
  "mothership" => {
    "repository" => "git@github.com:versapay/mothership.git",
    :packages => { },
    :gems => {
      :bundler => "1.0.18",
      "net-ssh-multi" => "1.0.1"
    },
    "environments" => {
      "production" => {
        "branch" => "master",
        "db_master_backups" => [
          { :every => '1.days', :keep => 30, :at => "'1:00 am'" },
          { :every => '1.month', :keep => 24, :at => "'start of the month at 1:00am'"}
        ]
      }
    }
  }
)
# Attributes applied no matter what the node has set already.
override_attributes({
  # Mothership should ALWAYS be in production
  :rails_app => {
    :environment => 'production'
  }
})
