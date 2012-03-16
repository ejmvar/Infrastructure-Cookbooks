Description
===========
Sets up a server to make alerts in redmine whenever a firewall or switch
config changes.  Switch and firewall configs are pushed to the server
and a cron job on the server scans the most recent push and creates an
alert if the configs has changed.
