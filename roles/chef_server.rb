name "chef_server"
description "The chef server that stores configuration templates and assigns roles and attributes to all of its client servers"
run_list(['chef-server','chef-server::apache-proxy'])
default_attributes(
  "chef_server" => {
    "webui_enabled" => true
    # "backups" => [
    #   { :every => '1.minute', :keep => 20},
    #   { :every => '1.day', :keep => 30 },
    #   { :every => '1.month', :keep => 24 }
    # ]
  }
)
