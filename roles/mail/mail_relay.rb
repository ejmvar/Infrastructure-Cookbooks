name "mail_relay"
description "Setup postfix to relay emails to sendgrid"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  'postfix',
  'postfix::sasl_auth'
])
# Attributes applied if the node doesn't have it set already.
#default_attributes()
# Attributes applied no matter what the node has set already.
override_attributes(
  :postfix => {
    :smtp_sasl_auth_enable => 'yes',
    :relayhost => "[smtp.sendgrid.net]:587",
    :header_size_limit => 4096000,
    :smtp_use_tls => 'yes',
    :smtp_sasl_user_name => "sasl_user_name",
    :smtp_sasl_passwd => "sasl_password",
    :mail_type => 'master'
  }
)

