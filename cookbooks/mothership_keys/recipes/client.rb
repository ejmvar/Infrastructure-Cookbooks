include_recipe "ssh"

mothership_server = search(:node, 'recipes:mothership_keys\\:\\:server') || []

mothership_server.each do |mothership|
  # Authorize the mothership server to access this server
  ssh_authorization do
    key mothership[:ssh][:public_key]
  end
end
