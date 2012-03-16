name "ldap-server"

description "Sets up an ldap server to handle authentication"
run_list(
  "recipe[openldap::server]",
  "recipe[openldap::ldapscripts]"
  )
default_attributes(
    "openldap" => {
      "server" => {
        "suffix" => "dc=example,dc=com",
        "admin" => "admin",
        "backups" => [
          { :every => "1.day", :keep => 30, :at => "'3:00am'"}
        ]
      }
    }
)

