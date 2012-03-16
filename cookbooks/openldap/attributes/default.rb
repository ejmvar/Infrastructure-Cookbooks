
default[:openldap][:groups] = ['adm', 'dialout', 'cdrom', 'floppy', 'audio', 'dip', 'video', 'plugdev']
default[:openldap][:password] = 'password'

default[:openldap][:server][:suffix] = "dc=example,dc=com"
default[:openldap][:server][:admin] = "admin"

default[:openldap][:server][:tmp_dir] = "/tmp/ldap"
default[:openldap][:server][:replica] = false

default[:openldap][:server][:auth_user] = "authenticate"

default[:openldap][:server][:sync_user] = "sync"

default[:openldap][:dashboard][:local_ldap] = true

default[:openldap][:server][:user_groups] = ['all_machines', 'operations', 'executives', 'developers']
default[:openldap][:server][:user_group_tree] = "System"
default[:openldap][:user_groups] = ['all_machines']

default[:openldap][:server][:log_level] = 512
default[:openldap][:server][:log_file] = "/var/log/ldap.log"

default[:openldap][:server][:policy_tree] = "policies"

default[:openldap][:server][:ldap_admin_groups] = ["operations", "executives"]
