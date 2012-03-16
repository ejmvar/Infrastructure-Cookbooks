knife exec -E 'nodes.all.each do |n|
puts "#{n.name}"
puts "  #{n.roles.join(",")}"
#n.roles.each do |r_name|
  #r = search(:role, "name:#{r_name}").first
  #puts "  #{r_name}"
  #puts "    #{r.description}"
#end
end
'
