#!/bin/bash
# This script prepares Ubuntu for use within the VersaPay infrastructure
# and is meant to be run on the Ubuntu image before turning it into a template

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "I really like you, but could you please run this as root." 1>&2
   exit 1
fi

# update / upgrade packages
apt-get update -y
apt-get upgrade -y
apt-get install build-essential wget ssl-cert git-core zlib1g-dev libssl-dev libreadline5-dev openssh-server -y

# install REE
ree_version='1.8.7-2011.03'
ree_filename="ruby-enterprise-$ree_version"
ree_symlink_path="/opt/ruby-enterprise"
ree_install_path="$ree_symlink_path-$ree_version"
ree_url="http://rubyenterpriseedition.googlecode.com/files/$ree_filename.tar.gz"

# Install REE
#
if [ ! -d $ree_install_path ]; then
  cd /tmp
  wget $ree_url
  tar zxf $ree_filename.tar.gz
  cd $ree_filename
  # Workaround bug in Ruby Enterprise Installer when using flag --dont-install-userful-gems
  # See: http://code.google.com/p/rubyenterpriseedition/issues/detail?id=42
  mkdir -p $ree_install_path/lib/ruby/gems/1.8/gems
  ./installer --auto=$ree_install_path --dont-install-useful-gems
  # Add Ruby Enterprise bin directory to the Path
  echo PATH="$ree_symlink_path/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games" > /etc/environment
  . /etc/environment
  # Symlink ruby
  ln -s $ree_install_path $ree_symlink_path
fi

. /etc/environment

# downgrade rake.  We slightly updated our ruby version but still use rake 0.8.7
gem install rake -v 0.8.7
gem uninstall rake -v 0.9.2

# Install and configure Chef
gem install ohai --no-rdoc --no-ri
gem install chef --no-rdoc --no-ri -v 0.10.4
