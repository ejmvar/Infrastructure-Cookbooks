name "ldap-replica"

description "Sets up an ldap server that slaves of the master ldap server"
run_list(
  "recipe[openldap::server]"
  )
default_attributes(
    "openldap" => {
      "server" => {
        "admin" => "replica",
        "replica" => true,
        "backups" => [
          { :every => '15.minutes', :keep => 72, :at => 15},
          { :every => "1.hour", :keep => 48, :at => 20 },
          { :every => "1.day", :keep => 30, :at => "'2:00 am'"}
        ]
      }
    }
)

