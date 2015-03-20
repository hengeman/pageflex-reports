#!/usr/bin/env ruby
# encoding: utf-8

#
# Note, this script will delete any and all XML and XLS files in the directory
# THAT IT IS RUN FROM! (not the directory that contains the script)
#
# Ensure you consider this before you run it.
#

require 'net/ftp'

inbox_host = 'axawealth.roi360.co.uk'
inbox_user = 'axawealthinbox'
inbox_pass = 'axawealth'
media_host = 'axawealth.roi360.co.uk'
media_user = 'axawealthmedia'
media_pass = 'axawealth'

# Remove existing xml and xls
Dir.entries('.').select { |e| e.match(/(\.xml$|\.xls$)/i) }.map do |file|
  File.delete file
end

puts 'Fetching xml'

# Get xml
Net::FTP.open(inbox_host, inbox_user, inbox_pass) do |ftp|
  xmls = ftp.nlst.select { |e| e.match(/\.xml$/i) }.sort do |x, y|
    ftp.mtime(x) <=> ftp.mtime(y)
  end
  abort 'No xml found on FTP' if xmls.size == 0
  ftp.gettextfile(xmls.last) # Get the latest xml file
  ftp.delete(xmls.first)     # Delete the oldest xml file
end

puts 'Generating report'

# Gen xls report
bin_path = File.expand_path('../bin', File.dirname(__FILE__))
xml_name = Dir.entries('.').find { |e| e.match(/\.xml$/i) }
system "#{bin_path}/custom_report.rb #{xml_name}"

puts 'Moving report to store'

# Put report on store
Net::FTP.open(media_host, media_user, media_pass) do |ftp|
  ftp.putbinaryfile(Dir.entries('.').find { |e| e.match(/\.xls$/) },
                    'store_product_report.xls')
end
