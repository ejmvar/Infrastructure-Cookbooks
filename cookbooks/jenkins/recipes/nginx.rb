include_recipe 'nginx::install_packages_and_extract_sources'

execute "install-nginx" do
  # Install nginx from source. Set error-log-path at compile time.
  command %{
    cd "/tmp" &&                                                \
    tar xzf nginx-#{node.nginx.version}.tar.gz &&               \
    cd nginx-#{node.nginx.version} &&                           \
    ./configure #{node.nginx.extra_configure_flags}             \
      --prefix=#{node[:nginx][:install_path]}                   \
      --error-log-path=#{node[:nginx][:log_dir]}/error.log      \
      #{node[:nginx][:extra_configure_flags]}                   \
    && make && make install
  }
  not_if { File.exists?(node[:nginx][:install_path]) }
end

include_recipe 'nginx::setup_service_and_common_configuration'

ssl_cert node.fqdn # generate ssl_cert

iptables_rule "input_jenkins_server" do
  chain "INPUT"
  dport 443
  destination node.ipaddress
  comment "Allow ssl access to ci server"
end

iptables_rule "input_jenkins_http_server" do
  chain "INPUT"
  dport 80
  destination node.ipaddress
  comment "Allow http access to redirect to ssl ci server"
end

nginx_vhost_proxy 'jenkins' do
  ssl_only true
  upstream ["127.0.0.1:#{node[:jenkins][:port]}"]
end

