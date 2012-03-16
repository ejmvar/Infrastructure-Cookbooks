default[:nginx][:version]               = '0.8.53'
default[:nginx][:install_path]          = "/opt/nginx-#{node[:nginx][:version]}"
default[:nginx][:dir]                   = "/opt/nginx"
default[:nginx][:pid_dir]               = "/var/run"
default[:nginx][:extra_configure_flags] = "--with-http_ssl_module --with-http_gzip_static_module"

default[:nginx][:log_dir]   = "/var/log/nginx"
default[:nginx][:conf_dir]  = "/etc/nginx"
default[:nginx][:user]      = "www-data"
default[:nginx][:binary]    = "/opt/nginx/sbin/nginx"

# nginx returns 413 if files are bigger than 20m
default[:nginx][:client_max_body_size] = "20m"

# From opscode recipe
default[:nginx][:keepalive]          = "on"
default[:nginx][:keepalive_timeout]  = 65
default[:nginx][:worker_processes]   = cpu[:total]
default[:nginx][:worker_connections] = 2048
default[:nginx][:server_names_hash_bucket_size] = 64

