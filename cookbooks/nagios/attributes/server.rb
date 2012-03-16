#
# Author:: Joshua Sierles <joshua@37signals.com>
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: nagios
# Attributes:: server
#
# Copyright 2009, 37signals
# Copyright 2009-2010, Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set[:nagios][:dir]       = "/etc/nagios3"
set[:nagios][:log_dir]   = "/var/log/nagios3"
set[:nagios][:cache_dir] = "/var/cache/nagios3"
set[:nagios][:state_dir] = "/var/lib/nagios3"
set[:nagios][:docroot]   = "/usr/share/nagios3/htdocs"
set[:nagios][:config_subdir] = "conf.d"

default[:nagios][:notifications_enabled]   = 0
default[:nagios][:check_external_commands] = true
default[:nagios][:default_contact_groups]  = %w(admins)
default[:nagios][:sysadmin_email]          = "root@localhost"
default[:nagios][:sysadmin_sms_email]      = "root@localhost"
default[:nagios][:server_auth_method]      = "htauth"

# This setting is effectively sets the minimum interval (in seconds) nagios can handle.
# Other interval settings provided in seconds will calculate their actual from this value, since nagios works in 'time units' rather than allowing definitions everywhere in seconds

default[:nagios][:templates] = Mash.new
default[:nagios][:interval_length] = 1

# Provide all interval values in seconds
default[:nagios][:default_host][:check_interval]     = 15
default[:nagios][:default_host][:retry_interval]     = 15
default[:nagios][:default_host][:max_check_attempts] = 1
default[:nagios][:default_host][:notification_interval] = 300

default[:nagios][:default_service][:check_interval]     = 60
default[:nagios][:default_service][:retry_interval]     = 15
default[:nagios][:default_service][:max_check_attempts] = 3
default[:nagios][:default_service][:notification_interval] = 86400 # once a day

default[:nagios][:medium_interval_service][:check_interval] = 300
default[:nagios][:medium_interval_service][:retry_interval] = 60
default[:nagios][:medium_interval_service][:max_check_attempts] = 5

default[:nagios][:long_interval_service][:check_interval] = 600
default[:nagios][:long_interval_service][:retry_interval] = 60
default[:nagios][:long_interval_service][:max_check_attempts] = 5

default[:nagios][:contacts] = Mash.new

default[:nagios][:send_grid][:api_user] = "sendgrid_user_email"
default[:nagios][:send_grid][:api_key] = "sendgrid_api_key"

default[:nagios][:clickatell][:user]     = "clickatel_user_id"
default[:nagios][:clickatell][:password] = "clickatel_password"
default[:nagios][:clickatell][:api_id]   = "clickatell_api_id"
