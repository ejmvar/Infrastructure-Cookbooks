# Example:
#
# ssh_authorication do
#   from some_node
# end
#
# OR
#
# ssh_authorization do
#   key <<-KEY
#     SOME SSH KEY
#   KEY
# end
define :ssh_authorization, :from => nil, :key => nil, :user => nil do

  params[:user] ||= node[:ssh][:user]
  node[:ssh][:authorized_hosts] ||= Array.new
  node[:ssh][:authorized_keys] ||= Array.new

  if params[:from]
    node[:ssh][:authorized_hosts] << params[:from].fqdn unless node[:ssh][:authorized_hosts].include?(params[:from].fqdn)
  end

  if params[:key]
    node[:ssh][:authorized_keys] << params[:key] unless node[:ssh][:authorized_keys].include?(params[:key])
  end

  # Generate our authorized keys file
  template "/home/#{params[:user]}/.ssh/authorized_keys" do

    # Find all the authorized hosts
    public_keys = node[:ssh][:authorized_hosts].collect do |fqdn|
      authed_node = (search(:node, "fqdn:#{fqdn}") || [])[0]
      if authed_node && authed_node[:ssh] && authed_node[:ssh][:public_key]
        authed_node[:ssh][:public_key].chomp
      else
        Chef::Log.info "Can't add node to authorized keys file. #{fqdn} does not have an ssh public key."
        nil
      end
    end.compact

    public_keys = public_keys + node[:ssh][:authorized_keys]

    # use this instead of tempate to append entries instead of replacing
    # public_keys.each do |key|
    #   execute "echo '#{key}' >> /home/#{params[:user]}/.ssh/authorized_keys" do
    #     not_if "cat /home/#{params[:user]}/.ssh/authorized_keys | grep '#{key}'"
    #   end
    # end
   source "authorized_keys.erb"
   cookbook "ssh"
   owner params[:user]
   group params[:user]
   mode  "0600"
   variables({
     :ssh_keys => public_keys
   })
 end
end
