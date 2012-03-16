node.rails_apps.each do |app_name|
  unless node[app_name][:environments][node.rails_app.environment][:disable_delayed_jobs]
    monit_process "#{app_name}_delayed_job" do
      pid_file "/data/#{app_name}/current/tmp/pids/delayed_job.pid"
      executable "cd /data/#{app_name}/current && ./script/delayed_job"
      user 'root' #node.rails_app.user We must use root user to get permission to kill process and restart
      group app_name
    end
  end
end
