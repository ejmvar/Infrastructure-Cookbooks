#
# Rakefile for Chef Server Repository
#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
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

require 'rubygems'
require 'chef'
require 'json'

# Load constants from rake config file.
require File.join(File.dirname(__FILE__), 'config', 'rake')

# Detect the version control system and assign to $vcs. Used by the update
# task in chef_repo.rake (below). The install task calls update, so this
# is run whenever the repo is installed.
#
# Comment out these lines to skip the update.

if File.directory?(File.join(TOPDIR, ".svn"))
  $vcs = :svn
elsif File.directory?(File.join(TOPDIR, ".git"))
  $vcs = :git
end

# Load common, useful tasks from Chef.
# rake -T to see the tasks this loads.

load 'chef/tasks/chef_repo.rake'

desc "Bundle a single cookbook for distribution"
task :bundle_cookbook => [ :metadata ]
task :bundle_cookbook, :cookbook do |t, args|
  tarball_name = "#{args.cookbook}.tar.gz"
  temp_dir = File.join(Dir.tmpdir, "chef-upload-cookbooks")
  temp_cookbook_dir = File.join(temp_dir, args.cookbook)
  tarball_dir = File.join(TOPDIR, "pkgs")
  FileUtils.mkdir_p(tarball_dir)
  FileUtils.mkdir(temp_dir)
  FileUtils.mkdir(temp_cookbook_dir)

  child_folders = [ "cookbooks/#{args.cookbook}", "site-cookbooks/#{args.cookbook}" ]
  child_folders.each do |folder|
    file_path = File.join(TOPDIR, folder, ".")
    FileUtils.cp_r(file_path, temp_cookbook_dir) if File.directory?(file_path)
  end

  system("tar", "-C", temp_dir, "-cvzf", File.join(tarball_dir, tarball_name), "./#{args.cookbook}")

  FileUtils.rm_rf temp_dir
end

desc "Create a new certificate authority key and cert"
task :ca_cert do
  $expect_verbose = true
  fqdn = ENV["FQDN"]
  fqdn =~ /^(.+?)\.(.+)$/
  hostname = $1
  domain = $2
  keyfile = "ca.#{fqdn.gsub('*', 'wildcard')}"
  raise "Must provide FQDN!" unless fqdn && hostname && domain
  puts "** Creating ca key for #{fqdn}"
  sh("(cd #{CADIR} && openssl genrsa 2048 > ca.key)")
  sh("(cd #{CADIR} && chmod 644 ca.key)")
  puts "* Generating CACertificate for #{fqdn}"
  tf = Tempfile.new("#{keyfile}.ssl-conf")
  ssl_config = <<EOH
[ req ]
distinguished_name = req_distinguished_name
prompt = no

[ req_distinguished_name ]
C                      = #{SSL_COUNTRY_NAME}
ST                     = #{SSL_STATE_NAME}
L                      = #{SSL_LOCALITY_NAME}
O                      = #{COMPANY_NAME}
OU                     = #{SSL_ORGANIZATIONAL_UNIT_NAME}
CN                     = #{fqdn}
emailAddress           = #{SSL_EMAIL_ADDRESS}
EOH
  tf.puts(ssl_config)
  tf.close
  sh("(cd #{CADIR} && openssl req -config '#{tf.path}' -new -x509 -days 3650 -key ca.key -out ca.crt)")
  sh("(cd #{CADIR} && cp ca.crt #{CADIR}/../cookbooks/certificates/files/default)")
end

desc "Create a new certificate authority signed ssl cert"
task :signed_ssl_cert do
  $expect_verbose = true
  fqdn = ENV["FQDN"]
  fqdn =~ /^(.+?)\.(.+)$/
  hostname = $1
  domain = $2
  keyfile = "#{fqdn.gsub('*', 'wildcard')}"
  raise "Must provide FQDN!" unless fqdn && hostname && domain
  puts "** Creating ssl key for #{fqdn}"
  sh("(cd #{CADIR} && openssl genrsa 2048 > #{keyfile}.key)")
  sh("(cd #{CADIR} && chmod 644 #{keyfile}.key)")
  puts "* Generating SSl Certificate for #{fqdn}"
  tf = Tempfile.new("#{keyfile}.ssl-conf")
  ssl_config = <<EOH
[ req ]
distinguished_name = req_distinguished_name
prompt = no

[ req_distinguished_name ]
C                      = #{SSL_COUNTRY_NAME}
ST                     = #{SSL_STATE_NAME}
L                      = #{SSL_LOCALITY_NAME}
O                      = #{COMPANY_NAME}
OU                     = #{SSL_ORGANIZATIONAL_UNIT_NAME}
CN                     = #{fqdn}
emailAddress           = #{SSL_EMAIL_ADDRESS}
EOH
  tf.puts(ssl_config)
  tf.close
  sh("(cd #{CADIR} && openssl req -config '#{tf.path}' -new -key #{keyfile}.key > #{keyfile}.csr)")
  sh("(cd #{CADIR} && openssl x509 -req -in #{keyfile}.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 3650 > #{keyfile}.crt)")
  sh("(cd #{CADIR} && cp #{keyfile}.crt #{keyfile}.fullcert && cat ca.crt >> #{keyfile}.fullcert)")
  sh("(cd #{CADIR} && cp #{keyfile}.* ../cookbooks/certificates/files/default)")
end

desc "create a ca certificate for the splunk server"
task :splunk_root_ca do
  $expect_verbose = true
  fqdn = ENV["FQDN"]
  fqdn =~ /^(.+?)\.(.+)$/
  hostname = $1
  domain = $2
  raise "Must provide FQDN!" unless fqdn && hostname && domain
  puts "** Creating ssl key for #{fqdn}"
  sh("(cd #{CADIR} && openssl genrsa -des3 -out splunk_ca.key 1024)")
  sh("(cd #{CADIR} && chmod 644 splunk_ca.key)")
  puts "* Generating SSl Certificate for #{fqdn}"
  tf = Tempfile.new("splunk_ca.ssl-conf")
  ssl_config = <<EOH
[ req ]
distinguished_name = req_distinguished_name
prompt = no

[ req_distinguished_name ]
C                      = #{SSL_COUNTRY_NAME}
ST                     = #{SSL_STATE_NAME}
L                      = #{SSL_LOCALITY_NAME}
O                      = #{COMPANY_NAME}
OU                     = #{SSL_ORGANIZATIONAL_UNIT_NAME}
CN                     = #{fqdn}
emailAddress           = #{SSL_EMAIL_ADDRESS}
EOH
  tf.puts(ssl_config)
  tf.close
  sh("cd #{CADIR} && openssl req -config '#{tf.path}' -new -key splunk_ca.key -out splunk_ca.csr")
  sh("cd #{CADIR} && openssl x509 -req -in splunk_ca.csr -sha1 -signkey splunk_ca.key -CAcreateserial -out splunk_ca.pem -days 1095")
  sh("cd #{CADIR} && cp splunk_ca.pem ../cookbooks/splunk/files/default")
end

desc "create a ca certificate for the splunk forwarder"
task :splunk_ssl_cert do
   $expect_verbose = true
  fqdn = ENV["FQDN"]
  fqdn =~ /^(.+?)\.(.+)$/
  hostname = $1
  domain = $2
  raise "Must provide FQDN!" unless fqdn && hostname && domain
  puts "** Creating ssl key for #{fqdn}"
  sh("(cd #{CADIR} && openssl genrsa -des3 -out #{fqdn}_splunk.key 1024)")
  sh("(cd #{CADIR} && chmod 644 #{fqdn}_splunk.key)")
  puts "* Generating SSl Certificate for #{fqdn}"
  tf = Tempfile.new("splunk_forwarder.ssl-conf")
  ssl_config = <<EOH
[ req ]
distinguished_name = req_distinguished_name
prompt = no

[ req_distinguished_name ]
C                      = #{SSL_COUNTRY_NAME}
ST                     = #{SSL_STATE_NAME}
L                      = #{SSL_LOCALITY_NAME}
O                      = #{COMPANY_NAME}
OU                     = #{SSL_ORGANIZATIONAL_UNIT_NAME}
CN                     = #{fqdn}
emailAddress           = #{SSL_EMAIL_ADDRESS}
EOH
  tf.puts(ssl_config)
  tf.close
  sh("cd #{CADIR} && openssl req -config '#{tf.path}' -new -key #{fqdn}_splunk.key -out #{fqdn}_splunk.csr")
  sh("cd #{CADIR} && openssl x509 -req -in #{fqdn}_splunk.csr -sha1 -CA splunk_ca.pem -CAkey splunk_ca.key -CAcreateserial -out #{fqdn}_splunk.pem -days 1095")
  sh("cd #{CADIR} && cat #{fqdn}_splunk.pem #{fqdn}_splunk.key splunk_ca.pem > #{fqdn}_splunk.fullcert")
  sh("cd #{CADIR} && cp #{fqdn}_splunk.fullcert ../cookbooks/splunk/files/default")
end
