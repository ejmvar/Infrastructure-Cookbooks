name "gem_proxy"
description "Gem proxy role applied to server dealing with gems caching from rubygems.  The gem proxy allows gems to be install on all systems without needing access to the internet by using the this server as a proxy"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  "iptables::gemproxy"
])
# Attributes applied if the node doesn't have it set already.
default_attributes(
  # Register eft3 to the set of rails_apps.
  "rails_apps" => ["rubygems_proxy"],
  # eft3 attributes
  "rubygems_proxy" => {
    "repository" => "https://github.com/fnando/rubygems_proxy.git",
    "packages" => {
    },
    "gems" => {
      "bundler" => "1.0.10"
    },
    "environments" => {
      "production" => {
        "branch" => "master"
      }
    }
  }
)
