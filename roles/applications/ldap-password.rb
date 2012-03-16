name "ldap-password"
description "Ldap Password role applied to server running user password management.  Ldap Password allows ldap users to view and modify their own account information."
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
#run_list([
#])
# Attributes applied if the node doesn't have it set already.
default_attributes(
  # Register eft3 to the set of rails_apps.
  "rails_apps" => ["ldap-password"],

  "nginx" => {
    "internal_only" => true
  },
  # alfred attributes
  "ldap-password" => {
    "repository" => "git://github.com/versapay/ldap-password.git",
    "packages" => {
    },
    "gems" => {
      "bundler" => "1.0.10"
    },
    "environments" => {
      "production" => {
        "branch" => "master",
        "ldap_password_policies" => true
      },
    }
  }
)
# Attributes applied no matter what the node has set already.
#override_attributes(
#)

