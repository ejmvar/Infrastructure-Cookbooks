Common Infrastructure
====================

Setup
--------
* Chef
  * Internal chef server is setup to deploy and manage all servers

* Dns server and slave/DHCP
  * Dns is used via a bind server that also servers dhcp via dhpd(role: dhcp-server), and a bind slave(dns-slave)

Internet Access
--------
* Only specific vms require access to the internet
* All packages are cached and intstalled from a local apt-caching proxy
* All gems are cached from a local gem proxy

Monitoring
--------
* Nagios
  * All services are linked to nagios for monitoring status and alerting
administrators of downtime

* Splunk
  * All vms are linked to splunk for collecting auditable data

Access
--------
* Ldap
  * An openldap server is setup with all machines linked to it.  Ssh
    access is granted via ldap with options for using passwords or ssh
public keys
  * Access to all applications is grated via ldap login and password

* Gatekeeper
  * A gatekeeper application is installed in order to grant users the
    ability to modify their own accounts

Email
--------
* A local postfix relay server is set up so that all servers send mail through a
  relay. Allowing you to change mail configuration for your entire
system through one server.

Backup
--------
* A local backup server is setup to recieve backups from all systems

Errbit
--------
* Application error notification is setup using errbit.

Mothership
---------
* Deployment is handled using mothership recipes.


