name "splunk_server"
description "Splunk server role. Splunk collects and organizes log information from all servers that are its clients"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  "splunk::server",
  "role[mail_server]"
])
# Attributes applied if the node doesn't have it set already.
override_attributes(
  "splunk" => {
    "alert_emails" => ["admin@example.com"],
    "redmine_api_key" => '',
    "web" => {
      "url" => 'splunk.example.com'
    },
    "forwarder" => {
      "ssl_password" => "password"
    }
  }
)
# Attributes applied no matter what the node has set already.
#override_attributes(
#)

