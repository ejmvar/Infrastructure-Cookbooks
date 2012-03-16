Applications
======================
To deploy a Rails, or Sinatra application first create a role for the
application.  As an example see roles/applications/errbit.rb.

This role sets up everything needed to deploy the application.

Note that the config/db.yml, config/ldap.yml, and
config/initializers/(hoptoad|errbit).rb are generated based on ldap
servers, database servers and errbit servers within the chef repo.

Deploying Applications
----------------------
Applications are deployed using the application role from above and the
roles from roles/deployment.

Examples Using Spiceweasel
--------------------------
## An application without a database
- vsphere gemproxy.example.com:
  - role[base] role[gem_proxy] role[app_server]
  - Ubuntu1004LTS.DHCP.Template
  - -d ree -x deploy -P password --mac-address "00:50:56:01:20:11" -E common --num-cpus 1 --memory 1024 --network "common.services.van0 - 10.0.9.0/24"

Roles applied are the application specific role for setting up
application variables and app_server for setting up passenger and nginx.

## An application with a database on one vm
    - vsphere mothership.example.com:
      - role[base] role[mothership] role[database_master] role[app_server] role[run_migrations]
      - Ubuntu1004LTS.DHCP.Template
      - -d ree -x deploy -P password --mac-address "00:50:56:01:20:06" -E common --num-cpus 2 --memory 2048 --network "common.services.van0 - 10.0.9.0/24"

The database_master and run_migrations roles are applied to install and
setup mysql and run migrations from the application.

## An application with a database slave, nginx proxy, database master,
multiple app servers, and a utility server.

    - vsphere app0.example.com:
      - role[base] role[mothership]
      - Ubuntu1004LTS.DHCP.Template
      - -d ree -x deploy -P password --mac-address "00:50:56:01:20:06" -E common --num-cpus 2 --memory 2048 --network "common.services.van0 - 10.0.9.0/24"

    - vsphere app1.example.com:
      - role[base] role[mothership]
      - Ubuntu1004LTS.DHCP.Template
      - -d ree -x deploy -P password --mac-address "00:50:56:01:20:06" -E common --num-cpus 2 --memory 2048 --network "common.services.van0 - 10.0.9.0/24"

    - vsphere utility0.example.com:
      - role[base] role[mothership]
      - Ubuntu1004LTS.DHCP.Template
      - -d ree -x deploy -P password --mac-address "00:50:56:01:20:06" -E common --num-cpus 2 --memory 2048 --network "common.services.van0 - 10.0.9.0/24"

    - vsphere db1.example.com:
      - role[base] role[mothership]
      - Ubuntu1004LTS.DHCP.Template
      - -d ree -x deploy -P password --mac-address "00:50:56:01:20:06" -E common --num-cpus 2 --memory 2048 --network "common.services.van0 - 10.0.9.0/24"

    - add:
      - role[database_slave] role[backup]
      - db1.example.com

    - add:
      - role[app_server]
      - app0.example.com

    - add:
      - role[utility_server] role[run_migrations] role[cron_jobs]
      - utility0.example.com

    - vsphere db0.example.com
      - role[base] role[mothership] role[database_master]
      - Ubuntu1004LTS.DHCP.Template
      - -d ree -x deploy -P password --mac-address "00:50:56:01:20:06" -E common --num-cpus 2 --memory 2048 --network "common.services.van0 - 10.0.9.0/24"

    - add:
      - role[backup]
      - db0.example.com

    - run:
      - role:backup_server
      - sudo -i chef-client

    - run:
      - role:mothership AND chef_environment:common
      - sudo -i chef-client

     - vsphere proxy.example.com
      - role[base] role[mothership] role[proxy]
      - Ubuntu1004LTS.DHCP.Template
      - -d ree -x deploy -P password --mac-address "00:50:56:01:20:06" -E common --num-cpus 2 --memory 2048 --network "common.services.van0 - 10.0.9.0/24"


In this example the vms for app servers, utility servers, and dabase
slaves are setup and then their specific roles(database_slave,
app_server ect) are added but not executed.

Next a db master server is created, since the other servers roles are
defined access to the db will be granted to them. 
The backup role is then added to the database master, the backup server is updated to allow access from the database_master and then the application specific roles are applied.

Finally a nginx round robin proxy is created to round robin between the
two app servers.
