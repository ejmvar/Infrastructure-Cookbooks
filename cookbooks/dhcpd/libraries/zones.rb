class Chef
  class Recipe
    def zones
      node[:dhcpd][:zones].keys
    end

    def reverse_zone(zone)
      zone.split('/').first.split('.')[0..2].reverse.join('.')
    end

    def sub_zone(zone)
      zone.split('/').first.split('.')[0..2].join('.')
    end

    def all_hosts
      hosts = {}
      node[:dhcpd][:zones].each do |zone, config|
        hosts = hosts.merge(config)
      end
      hosts
    end
  end
end

