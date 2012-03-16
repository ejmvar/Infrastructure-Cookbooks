name "redmine"
description "Redmine role. Apply to servers running redmine. Redmine is a project management tool used for organizing our team"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
#run_list([
#])
# Attributes applied if the node doesn't have it set already.
default_attributes(
  # Register eft3 to the set of rails_apps.
  "rails_apps" => ["redmine"],

  # eft3 attributes
  "redmine" => {
    "repository" => "https://github.com/edavis10/redmine.git",
    "packages" => {
      "imagemagick" =>  nil,
      "librmagick-ruby" => nil
    },
    "gems" => {
      "rails" => "2.3.5",
      "mysql" => "2.8.1",
      "i18n" => "0.4.2",
      "prawn" => "0.11.1",
      "hoptoad_notifier" => "2.4.11"
    },
    "environments" => {
      "production" => {
        "branch" => "master",
        "secure_db_connection" => true,
        "db_master_backups" => [
          { :every => '1.day', :keep => 30, :at => "'1:00am'" },
          { :every => '1.month', :keep => 24, :at => "'start of month at 3:00am'" }
        ],
        "db_slave_backups" => [
          { :every => "15.minutes", :keep => 72, :at => 15 },
          { :every => '1.hour', :keep => 48, :at => 30 }
        ],
        "file_backups" => [
          { :name => "Files", :paths => ['files'], :every => "1.day", :keep => 30, :at => "'2:00am'" }
        ]
      },
      "staging" => {
        "branch" => "staging",
        "secure_db_connection" => true
      }
    }
  }
)
# Attributes applied no matter what the node has set already.
#override_attributes(
#)

