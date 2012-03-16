Installation
============
Chef Server
-----------
Setup a vm with a static ip address and install chef server by running
the script from bootstrap/install.sh.

DNS Server
-----------
Setup a vm with a static ip address.

Configure your local machine as a knife client of the chef server

Copy validation.pem from the chef server to your local ~/.chef directory

copy bootstrap/after_ree_bootstrap.erb to ~/.chef/ree.erb

edit ~/.chef/ree.erb line 7 to the correct location of your validation.pem

run sudo knife bootstrap <IP ADDRESS OF NEW VM> -r "role[base], role[dhcp-server]" -d ree -x deploy -P password -E common -s "https://<IP ADDRESS OF CHEF SERVEr>"  --sudo

DNS SLAVE
---------
sudo knife bootstrap <IP ADDRESS OF NEW VM> -r "role[base], role[dns-slave]" -d ree -x deploy -P password -E <ENVIRONMENT> -s "https://<IP ADDRESS OF CHEF SERVER>" --sudo

THE REST
---------
The rest of the infrastructure can be installed using spiceweasel and
the yml files in the spiceweasel folder.
