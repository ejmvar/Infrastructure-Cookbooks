#!/usr/bin/env ruby
#
# Check the age of the latest backups
#

require 'rubygems'
require 'choice'

EXIT_OK = 0
EXIT_WARNING = 1
EXIT_CRITICAL = 2
EXIT_UNKNOWN = 3

Choice.options do
  header ''
  header 'Specific options:'

  option :warning_age do
    short '-wa'
    long '--warning-age=VALUE'
    desc 'Warning age in minutes'
    cast Integer
  end

  option :critical_age do
    short '-ca'
    long '--critical-age=VALUE'
    desc 'Critical age in minutes'
    cast Integer
  end

  option :backup_path do
    short '-p'
    long '--backup_path=VALUE'
    desc 'Path where backups live'
    cast String
  end
end

c = Choice.choices

c[:warning_age] ||= 15
c[:critical_age] ||= 60
c[:backup_path] ||= '/data/backup/db'

results = []
output = []

databases = `ls #{c[:backup_path]}`

if databases.empty?
  puts "CRITICAL: Backup directory #{c[:backup_path]} does not exist"
  exit(EXIT_CRITICAL)
end

databases.each do |db|
  db.strip!
  last_backup = `ls -S -t #{c[:backup_path]}/#{db}/minutely*`.first.strip
  if last_backup.empty?
    output << "Critical: No backup directory for database '#{db}'"
    results << :critical
  else
    last_backup_modification_date = File.mtime(last_backup)
    if last_backup_modification_date > Time.now - 60 * c[:warning_age]
      results << :ok
     elsif last_backup_modification_date > Time.now - 60 * c[:critical_age]
       output << "Warning: Last backup of #{db}: #{last_backup_modification_date}"
       results << :warning
     else
       output << "Critical: Last backup of #{db}: #{last_backup_modification_date}"
       results << :critical
     end
  end
end

if results.include?(:critical)
  puts "CRITICAL: #{output.join(' - ')}"
  exit(EXIT_CRITICAL)
elsif results.include?(:warning)
  puts "WARNING: #{output.join(' - ')}"
  exit(EXIT_WARNING)
elsif results.include?(:ok)
  puts "OK: Last backup file created less than #{c[:warning_age]} minutes ago"
  exit(EXIT_OK)
else
  exit(EXIT_UNKNOWN)
end
