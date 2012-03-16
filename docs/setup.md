Chef Gem
========
For deployment we use a customized version of chef because
* We need our knife ssh commands to return exit codes to indicate
  success or failure
* We only want to enter a knife sudo password if we have not already
  provided it

We use the knife_ssh_error_codes branch of chef visable at
https://github.com/versapay/chef/tree/knife_ssh_error_codes

To install run the following
    git clone -b knife_ssh_error_codes git@github.com:versapay/chef.git
    cd chef
    (sudo) rake install

knife-vsphere Gem
=================
We use our knife-vsphere gem to create and bootstrap vsphere vms

To install run the following
    git clone git@github.com:versapay/knife-vsphere.git
    cd knife-vsphere
    rake gem
    (sudo) gem install pkg/knife-vsphere-0.1.5.gem

spiceweasel Gem
===============
We use spiceweasel to assist in mass deployment of vsphere vms

To install run the following
    git clone git@git.versapay.com:spiceweasel
    cd spiceweasel
    (sudo) rake install

Setting up your machine as a knife vsphere friendly chef client
===============================================================
* Using either ssh access to the chef server or the chef web ui create an
chef client for your laptop and setup following http://wiki.opscode.com/display/chef/Installing+Chef+Server+on+Debian+or+Ubuntu+using+Packages#InstallingChefServeronDebianorUbuntuusingPackages-CreateaKnifeClientforYourLaptop%2FDesktop

* Setup vsphere configuration following the configuration instructions
  from https://github.com/versapay/knife-vsphere

Creating A bootstrap Template
=============================
* Copy bootstrap/after_ree_bootstrap.erb to ~/.chef/bootstrap/ree.erb
* From chef server copy /home/deploy/.chef/validation.pem to your local
~/.chef directory
* Update line 7 of ~/.chef/bootstrap/ree.erb to have the location of
  the validation.pem you just copied
