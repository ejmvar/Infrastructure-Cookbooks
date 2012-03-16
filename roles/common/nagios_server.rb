name "nagios_server"
description "A Nagios monitoring server. Monitors all servers for network or hardware issues and sends out notifications if there is an error"
run_list(
  "recipe[nagios::server]",
  "role[mail_server]"
)

default_attributes({
  :nagios => {
    # All our contacts to send out alerts to
    :contacts => {
      :admin_1 => {
        :email => "admin@example.com",
        :cell => '1234567890'
      }
    }
  }
})
