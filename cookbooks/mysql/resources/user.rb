actions :create_user

attribute :username,          :kind_of => String
attribute :password,          :kind_of => String
attribute :host,              :kind_of => String, :default => 'localhost'
attribute :database,          :kind_of => String

# Grants the user FLUSH and PROCESS privileges
attribute :admin_privileges,  :equal_to => [ true, false], :default => false

