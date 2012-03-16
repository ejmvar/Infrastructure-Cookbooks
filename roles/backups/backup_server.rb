name "backup_server"
description "A server to store and manage backups from the rest of the environment"
run_list(['chef-backup::backup_server'])
default_attributes(
  "backup_server" => {
    "backups" => [
      { :every => '1.day' }
    ]
  }
)
