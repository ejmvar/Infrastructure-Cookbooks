default[:rails_app][:user]  = "deploy"
default[:rails_app][:group] = "deploy"
default[:rails_app][:deploy_dir] = "/data"
default[:rails_app][:shared_dirs] = %W( config log pids system bundle files )
default[:rails_app][:packages] = { "git-core" => nil, "libxslt1-dev" => nil, "libxml2-dev" => nil, "libmysqlclient-dev" => nil }
default[:rails_app][:gems] = { 'rake' => nil }
default[:rails_app][:environments] = %W( staging demo production )
default[:rails_app][:run_migration_role] = "run_migrations"
default[:rails_app][:environment_variables] = {}
