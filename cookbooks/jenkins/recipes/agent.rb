include_recipe "jenkins::default"

directory "/home/jenkins/agent" do
  recursive true
  owner "jenkins"
  mode 0700
end

search(:node, "role:jenkins_server").each do |jenkins_server|
  ssh_authorization do
    from jenkins_server
    user 'jenkins'
  end

  iptables_rule "input_ssh_jenkins_server_#{jenkins_server.hostname}" do
    dport 22
    source jenkins_server.ipaddress
    chain 'INPUT'
    comment "Allow ssh access from jenkins server"
  end

  ruby_block "write deploy keys to git clone eft3" do
    block do
      File.open("/home/jenkins/.ssh/id_rsa.pub", "w") do |f|
        f.print(jenkins_server[:jenkins][:deploy_public_key])
      end
      File.open("/home/jenkins/.ssh/id_rsa", "w") do |f|
        f.print(jenkins_server[:jenkins][:deploy_private_key])
      end
    end
  end

  git = search(:node, "roles:git-server")[0]
  bash "add git ssh key" do
    code "ssh git@#{git[:fqdn]} -o 'StrictHostKeyChecking no' 2>&1 | grep ' following access'"
    user 'jenkins'
  end

end

