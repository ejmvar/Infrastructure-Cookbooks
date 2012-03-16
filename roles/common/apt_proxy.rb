name "apt_proxy"
description "The apt proxy. Apt proxy enable ubuntu packages to be installed by servers without the servers needing access to the internet.  The apt proxy fetches and caches the packages and servers them to its client servers"
run_list(['apt::cacher'])
