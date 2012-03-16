name "dhcp-server"
description "Assigns IP addresses and host names of new machines based on the machines mac address"
run_list("recipe[dhcpd::server]", "recipe[bind::server]")
default_attributes(
  "dhcpd" => {
    "domain" => "example.com",
    "routers" => [ "10.0.9.1" ],
    "broadcast" => "10.0.9.255",
    "authoritative" => true,
    "zones" => {
      # -----------------------------------------------
      # -----------------------------------------------
      # COMMON
      # -----------------------------------------------
      # COMMON VLAN
      # -----------------------------------------------
      "10.0.9.0/24" => {
        'templateVm' => { :ip_address => '10.0.9.254' },
        'chef0-van0-common' => { :ip_address => '10.0.9.10' },
        'dns0-van0-common' => { :ip_address => '10.0.9.11'},
        'dns1-van0-common' => { :ip_address => "10.0.9.12" },
        'apt-cache-van0-common' => { :mac_address => "00:50:56:01:20:00", :ip_address => "10.0.9.20" },
        'ldap0-van0-common' => { :mac_address => "00:50:56:01:20:01", :ip_address => "10.0.9.21" },
        'ldap1-van0-common' => { :mac_address => "00:50:56:01:20:02", :ip_address => "10.0.9.22" },
        'nagios0-van0-common' => { :mac_address => "00:50:56:01:20:03", :ip_address => "10.0.9.31", :cnames => "nagios" },
        'splunk0-van0-common' => { :mac_address => "00:50:56:01:20:04", :ip_address => "10.0.9.32", :cnames => "splunk" },
        "mothership0-van0-common" => { :mac_address => "00:50:56:01:20:06", :ip_address => "10.0.9.50" },
        "errbit0-van0-common" => { :mac_address => "00:50:56:01:20:07", :ip_address => "10.0.9.60" },
        "smtp0-van0-common" => { :mac_address => "00:50:56:01:20:08", :ip_address => "10.0.9.65" },
        "gems0-van0-common" => { :mac_address => "00:50:56:01:20:10", :ip_address => "10.0.9.75" },
        "gemproxy-van0-common" => { :mac_address => "00:50:56:01:20:11", :ip_address => "10.0.9.80" },
        "gatekeeper0-van0-common" => { :mac_address => "00:50:56:01:20:12", :ip_address => "10.0.9.85" }
      },
      # -----------------------------------------------
      #COMMON THINGS THAT REQUIRE SSH ACCESS
      # -----------------------------------------------
      "10.0.10.0/24" => {
        "git0-van0-common" => { :mac_address => "00:50:56:01:20:05", :ip_address => "10.0.10.40" },
        "backup0-van0-common" => { :mac_address => "00:50:56:01:20:09", :ip_address => "10.0.10.70" },
        "nessus-test" => { :mac_address => "00:50:56:01:21:09", :ip_address => "10.0.10.10" }
      },
      # DEVELOPMENT VLAN
      "10.0.100.0/24" => {
        'ci0-van0-dev' => { :mac_address => "00:50:56:01:20:50", :ip_address => "10.0.100.10"},
        'ci-agent0-van0-dev' => { :mac_address => "00:50:56:01:20:51", :ip_address => "10.0.100.11" },
        'ci-agent1-van0-dev' => { :mac_address => "00:50:56:01:20:52", :ip_address => "10.0.100.12" },
        'ci-agent2-van0-dev' => { :mac_address => "00:50:56:01:20:53", :ip_address => "10.0.100.13" },
        'ci-agent3-van0-dev' => { :mac_address => "00:50:56:01:20:54", :ip_address => "10.0.100.14" },
        'alfred0-van0-dev'    => { :mac_address => "00:50:56:01:20:55", :ip_address => "10.0.100.40" }
      },
     # INTERNAL VLAN TO ALLOW QUERY and RECURSION
      "10.0.0.0/8" => {}
    }
  }
)
override_attributes(
  "bind" => {
    "forwarders" => ["8.8.8.8", "8.8.4.4"]
  }
)
