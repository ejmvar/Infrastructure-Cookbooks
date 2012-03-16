maintainer       "Ben Mabey"
maintainer_email "ben@benmabey.com"
license          "MIT"
description      "Installs/Configures jenkins"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1"

depends "apt"
depends "nginx"
depends "java"
supports "ubuntu"
