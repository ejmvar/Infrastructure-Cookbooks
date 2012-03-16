name "config-manager"
description "The configuration managment roles is applied to a server that pulls configurations from the switches and firewalls and creates alerts in redmine if these configurations are changed"
run_list("recipe[tftp::default]", "recipe[configuration-manager::default]")
default_attributes(
  "configuration_manager" => {
    "redmine_api_key" => "",
    "redmine_project" => "",
    "redmine_user_id" => nil
  }
)

