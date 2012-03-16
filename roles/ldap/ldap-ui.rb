name "ldap-ui"

description "Ui for the ldap server"
run_list(
  "recipe[openldap::dashboard]"
  )
