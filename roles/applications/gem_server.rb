name "gem_server"
description "Gem Server role applied to server dealing with gems via geminabox repo.  The gme server allows for private gems to be installed from this server"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
#run_list([
#])
# Attributes applied if the node doesn't have it set already.
default_attributes(
  # Register eft3 to the set of rails_apps.
  "rails_apps" => ["geminabox"],
  # eft3 attributes
  "geminabox" => {
    "repository" => "https://github.com/cwninja/geminabox.git",
    "packages" => {
    },
    "gems" => {
      :bundler => "1.0.18",
      "geminabox" => "0.3.2"
    },
    "environments" => {
      "production" => {
        "branch" => "master"
      }
    }
  }
)
