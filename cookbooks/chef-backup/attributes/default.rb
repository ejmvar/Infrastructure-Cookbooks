#default[:backup][:jobs] = {'minutely' => {:keep => 60, :every => "1.minute", :mysql_databases => {'redmine_production' => {:username, :password, :host}}, :mongo_databases => {'errbit_prod' => {:host, :port}}, :folders => [], :sync_folders => []}}
default[:backup][:jobs] = {}
default[:backup][:description] = "a chef generated server backup"

default[:backup][:mysql_backup_user] = 'backup'

default[:backup][:s3][:aws_access_key] = "Access_key"
default[:backup][:s3][:aws_secret_key] = "Secret_access_key"
default[:backup][:s3][:bucket_region] = 'us-east-1'

# default[:backup][:s3][:sync_path] = "/files"

# List directories which you want to sync.
# default[:backup][:s3][:sync_directories] = ["/tmp"]

default[:backup][:mail][:on_success] = true
default[:backup][:mail][:on_failure] = true
default[:backup][:mail][:from_address] = "backup@example.com"
default[:backup][:mail][:to_address] = "admin@example.com"
default[:backup][:mail][:domain] = "example.com"
