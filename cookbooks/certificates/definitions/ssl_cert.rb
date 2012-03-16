define :ssl_cert do

  destdir = params[:destination] || node.certificates_dir
  fqdn = params[:name] || node.fqdn
  fqdn =~ /^(.+?)\.(.+)$/
  hostname = $1
  domain = $2
  cert_owner = params[:owner] || 'www-data'
  cert_group = params[:group] || 'www-data'

  directory destdir

  cookbook_file "#{destdir}/#{fqdn}.key" do
    source "#{fqdn}.key"
    cookbook "certificates"
    mode "0640"
    owner cert_owner
    group cert_group
  end

  cookbook_file "#{destdir}/#{fqdn}.crt" do
    source "#{fqdn}.crt"
    cookbook "certificates"
    mode "0644"
    owner cert_owner
    group cert_group
  end

  cookbook_file "#{destdir}/#{fqdn}.fullcert" do
    source "#{fqdn}.fullcert"
    cookbook "certificates"
    mode "0644"
    owner cert_owner
    group cert_group
  end
end
