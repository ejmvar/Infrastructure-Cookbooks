name "errbit"
description "Errbit handles collection and notification of error in any of our applications"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
])
# Attributes applied if the node doesn't have it set already.
default_attributes(
  # Register mothership to the set of rails_apps.
  "rails_apps" => ["errbit"],

  # errbit attributes
  "errbit" => {
    "repository" => "git://github.com/errbit/errbit.git",
    :packages => { 
        'mongodb' => nil
     },
    :gems => {
      :bundler => "1.0.18"
    },
    :error_notification => {
      "notifier" => "HoptoadNotifier",
      "api_key" => "---------"
    },
    "environments" => {
      "production" => {
        "branch" => "master",
        "db_master_backups" => [
          { :every => "1.day", :keep => 30, :at => "'1:00 am'" },
          { :every => "1.month", :keep => 24, :at => "'start of month at 1:00am'" }
        ]
      }
    }
  }
)
# Attributes applied no matter what the node has set already.
# override_attributes({
#   # Errbit should ALWAYS be in production
#   :rails_app => {
#     :environment => 'production'
#   }
# })
