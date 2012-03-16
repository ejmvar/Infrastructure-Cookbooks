name "dns-slave"
description "A dns server that acts as a slave off the master dns server.  Clients may use either the master or slave or both for resolving dns queries"
run_list("recipe[bind::server]")
default_attributes(
  "bind" => {
    "type" => "slave",
    "backups" => [
      {:every => "1.day", :keep => 30, :at => "'2:00 am'"},
      {:every => "1.month", :keep => 24, :at => "'start of month at 2:00am'"}
    ]
   }
)
