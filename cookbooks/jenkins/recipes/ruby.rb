# We don't use RVM
#include_recipe "jenkins"
#
#rvm_user do
#  user "jenkins"
#  rubies node[:jenkins][:rvm][:rubies]
#  packages []
#  default_ruby node[:jenkins][:rvm][:default_ruby]
#  gems node[:jenkins][:rvm][:gems]
#end
#
#jenkins_plugin "ruby" => "1.2", "rubyMetrics" => "1.4", "rake" => "1.6.3"
