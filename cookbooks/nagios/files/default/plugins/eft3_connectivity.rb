#!/usr/bin/env ruby
#
# Nagios check for eft3 connectivity

require 'rubygems'
require 'net/http'
require 'uri'

EXIT_OK = 0
EXIT_WARNING = 1
EXIT_CRITICAL = 2
EXIT_UNKNOWN = 3


%w(
  https://localhost:443/status
  https://github.com
  https://chef:443
)
url = URI.parse("http://#{c[:host]}:8983/")
res = Net::HTTP.start(url.host, url.port) do |http|
  http.get("/#{c[:prefix]}/select/?q=#{c[:query]}&version=#{c[:version]}&start=#{c[:start]}&rows=#{c[:rows]}&indent=on")
end
