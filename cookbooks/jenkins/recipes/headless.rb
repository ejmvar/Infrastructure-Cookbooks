# This recipe was inspired by this post:
# http://blog.kabisa.nl/2010/05/24/headless-cucumbers-and-capybaras-with-selenium-and-jenkins/
#
# To use this in your Hudson jobs you should do it like so:
#
# #!/bin/bash
# export DISPLAY=:99
# /etc/init.d/xvfb start
# rake cucumber
# RESULT=$?
# /etc/init.d/xvfb stop
# exit $RESULT

# this is used to find the firefox preference file, which is stored in a random directory
FIREFOX_PREFERENCES_FILE = %q{find /home/jenkins/.mozilla/ -name "prefs.js"}.freeze

def add_firefox_preference(preference)
  script "add #{preference}" do
    interpreter "bash"
    user        "jenkins"
    group       "jenkins"
    cwd         "/home/jenkins"
    not_if      %q{grep '#{preference}' `#{FIREFOX_PREFERENCES_FILE}`}
    code        <<-C
      echo '#{preference}' >> `#{FIREFOX_PREFERENCES_FILE}`
    C
  end
end

package "xvfb" do
  action :install
end

template "/etc/init.d/xvfb" do
  owner  "jenkins"
  mode   0700
  source "xvfb-init.erb"
end

package "firefox" do
  action :install
end

bash "delete existing firefox preferences" do
  code "rm -fr ~/.mozilla"
  user "jenkins"
  only_if "ls ~/.mozilla"
end

# because of the way firefox generates its preference folder in a random location, 
# we have to start it up in order to modify the preferences.

script "generate mozilla prefs.js" do
  interpreter "bash"
  user        "jenkins"
  group       "jenkins"
  cwd         "/home/jenkins"
  not_if      %q{test -d /home/jenkins/.mozilla && test -f `#{FIREFOX_PREFERENCES_FILE}`}
  code        <<-C
    export DISPLAY=:99
    export HOME=/home/jenkins
    echo 'Starting Xvfb'
    /etc/init.d/xvfb start
    echo 'Starting Firefox'
    firefox &
    sleep 10
    echo 'Killing Firefox'
    kill $(pidof firefox-bin)
    echo 'Stopping Xvfb'
    /etc/init.d/xvfb stop
  C
end

add_firefox_preference('user_pref("browser.sessionstore.enabled", false);')
add_firefox_preference('user_pref("browser.sessionstore.resume_from_crash", false);')
