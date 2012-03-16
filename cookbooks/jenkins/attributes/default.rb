set_unless[:jenkins][:port]  = 8080
set_unless[:jenkins][:domain]  = "jenkins.codebox"
set_unless[:jenkins][:git_user_name]  = "Hudson"
set_unless[:jenkins][:plugins]  = {"greenballs" => "1.6", "git" => "0.8.3", "rake" => "1.7.3", "rubyMetrics" => "1.4.6"}
set_unless[:jenkins][:apt_repository]  = "jenkins-ci" # this version has the most recent builds

# We don't use rvm in prod
# set_unless[:jenkins][:rvm][:rubies] = %w[1.8.7-p248]
# set_unless[:jenkins][:rvm][:packages] = %w[zlib]
# set_unless[:jenkins][:rvm][:default_ruby] = "1.8.7-p248"
# set_unless[:jenkins][:rvm][:gems] = {"all_versions" => {'bundler' => '0.9.25', 'bundler08' => '0.8.5', 'rake' => '0.8.7'}}
