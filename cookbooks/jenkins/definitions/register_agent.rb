define :register_agent do
  server = params[:server]
  base_url = "http://#{server.fqdn}:#{server.jenkins.port}"

  agent_name = `hostname`.chomp

  agent_url = "#{base_url}/computer/#{agent_name}/"

  def curl_post(url, params)
    #ps = []
    #params.each do |k, v|
    #  ps << "'#{k}'='#{v}'"
    #end
    #cmd = %{curl -F "#{ps.join(';')}" #{url}}
    ps = []
    params.each do |k, v|
      ps << "-d '#{k}=#{v}'"
    end
    cmd = %{curl #{ps.join(' ')} #{url}}
    Chef::Log.info cmd
    Chef::Log.info `#{cmd}`
  end

  unless `curl #{agent_url}`['404']
    Chef::Log.info "Agent #{agent_name} exits already."
  else
    Chef::Log.info "Agent #{agent_name} does not exit. Let's register it."
    curl_post(base_url + "/computer/createItem", 
      { "name" => agent_name,
        "mode" => "hudson.slaves.DumbSlave$DescriptorImpl"
      }
    )

    curl_post(base_url + "/computer/doCreateItem", 
      { "name" => agent_name,
        #"_.nodeDescription" => "",
        "_.numExecutors" => "1",
        "_.remoteFS" => "/home/jenkins",
        #"_.labelString" => "",
        "mode" => "NORMAL",
        "stapler-class" => "hudson.os.windows.ManagedWindowsServiceLauncher",
        #"_.userName" => "",
        #"_.password" => "",
        "stapler-class" => "hudson.slaves.CommandLauncher",
        #"_.command" => "",
        "stapler-class" => "hudson.slaves.JNLPLauncher",
        #"_.tunnel" => "",
        #"_.vmargs" => "",
        "stapler-class" => "hudson.plugins.sshslaves.SSHLauncher",
        "_.host" => node.fqdn,
        #"_.username" => "",
        #"_.password" => "",
        #"_.privatekey" => "",
        "_.port" => "22",
        #"_.jvmOptions" => "",
        "stapler-class" => "hudson.slaves.RetentionStrategy$Always",
        "stapler-class" => "hudson.slaves.SimpleScheduledRetentionStrategy",
        #"retentionStrategy.startTimeSpec" => "",
        #"retentionStrategy.upTimeMins" => "",
        "retentionStrategy.keepUpWhenActive" => "on",
        "stapler-class" => "hudson.slaves.RetentionStrategy$Demand",
        #"retentionStrategy.inDemandDelay" => "",
        #"retentionStrategy.idleDelay" => "",
        "stapler-class-bag" => "true",
        "type" => "hudson.slaves.DumbSlave$DescriptorImpl",
#'json' => '{"name": "mynewnode", "nodeDescription": "", "numExecutors": "1", "remoteFS": "/home/deploy/jenkins", "labelString": "", "mode": "NORMAL", "": ["hudson.os.windows.ManagedWindowsServiceLauncher", "hudson.slaves.RetentionStrategy$Always"], "launcher": {"stapler-class": "hudson.os.windows.ManagedWindowsServiceLauncher", "userName": "", "password": ""}, "retentionStrategy": {"stapler-class": "hudson.slaves.RetentionStrategy$Always"}, "nodeProperties": {"stapler-class-bag": "true"}, "type": "hudson.slaves.DumbSlave$DescriptorImpl"}',
#"Submit" => "Save"
        
      }
    )

  end
end
