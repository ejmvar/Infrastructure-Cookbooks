#!/bin/bash
# This script should be run on a freshly deployed vm from ubuntu-template (vm template created by all_servers.sh) after changing hostname with change_hostname.sh and setup apt sources with setup_apt_sources.sh
# it uses chef-solo to run a chef recipe to install a chef server

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "I really like you, but could you please run this as root." 1>&2
   exit 1
fi

echo "MAKE SURE YOU HAVE run ssh-keygen as deploy"
su ubuntu -c "ssh-keygen"

# update / upgrade packages
apt-get update -y
apt-get upgrade -y
apt-get install build-essential wget curl ssl-cert git-core zlib1g-dev libssl-dev libreadline5-dev openssh-server ruby ruby-dev libopenssl-ruby rdoc ri irb -y

# install rubygems
cd /tmp
wget http://production.cf.rubygems.org/rubygems/rubygems-1.7.2.tgz
tar zxf rubygems-1.7.2.tgz
cd rubygems-1.7.2
ruby setup.rb --no-format-executable

# downgrade rake.  We slightly updated our ruby version but still use rake 0.8.7
# gem install rake -v 0.8.7
# gem uninstall rake -v 0.9.2

# install chef
gem install chef --no-ri --no-rdoc -v 0.10.4
gem install ohai --no-ri --no-rdoc

mkdir -p /etc/chef
#setup chef solo file
(
cat <<EOP
file_cache_path "/tmp/chef-solo"
cookbook_path "/tmp/chef-solo/cookbooks"
EOP
) > /etc/chef/solo.rb

# setup chef.json file
(
cat <<EOP
{
  "chef_server": {
    "server_url": "http://`hostname -f`:4000",
    "init_style": "init",
    "webui_enabled": true
  },
  "run_list": [ "recipe[chef-server::rubygems-install]" ]
}
EOP
) > ~/chef.json

#bootstrap to install chef server
chef-solo -c /etc/chef/solo.rb -j ~/chef.json -r http://s3.amazonaws.com/chef-solo/bootstrap-0.10.4.tar.gz

cd ~
su deploy -c "git clone -b master https://github.com:versapay/Infrastructure-Cookbooks.git"

echo " Setup knife. Accept all default values except chef repo path which should be /home/ubuntu/chef-repo and chef server url which should use https"

knife configure -i --defaults -r "/home/ubuntu/chef-repo" -y

chown ubuntu:ubuntu -Rf /home/ubuntu/.chef

# add environments
su deploy -c 'knife environment from file /home/ubuntu/chef-repo/environments/development.rb'
su deploy -c 'knife environment from file /home/ubuntu/chef-repo/environments/demo.rb'
su deploy -c 'knife environment from file /home/ubuntu/chef-repo/environments/production.rb'
su deploy -c 'knife environment from file /home/ubuntu/chef-repo/environments/staging.rb'
su deploy -c 'knife environment from file /home/ubuntu/chef-repo/environments/common.rb'

su deploy -c "cd ~/chef-repo && rake install"

chef-client

mkdir -p /var/www
cp /etc/chef/validation.pem /home/deploy/.chef/validation.pem

su deploy -c "knife exec -E \"nodes.transform('name:`hostname -f`') { |n| n.chef_environment('common') }\""

su deploy -c 'knife node run_list add `hostname -f` "role[base]" '
su deploy -c 'knife node run_list add `hostname -f` "role[chef_server]" '

# after recipes run the chef server will be accessible over https
knife configure --defaults -r "/home/ubuntu/chef-repo" -s "https://`hostname -f`" -y

chef-client
