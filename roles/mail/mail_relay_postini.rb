name "mail_relay_postini"
description "Setup postfix to realy emails to postini"
# List of recipes and roles to apply. Requires Chef 0.8, earlier versions use 'recipes()'.
run_list([
  'postfix'
])
# Attributes applied if the node doesn't have it set already.
#default_attributes()
# Attributes applied no matter what the node has set already.
override_attributes(
  :postfix => {
    :mail_type => 'master'
  }
)
