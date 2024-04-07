#!/usr/bin/env ruby
ENV['PATH'] = '/opt/homebrew/bin:' + ENV['PATH']
require 'open-uri'
require 'rubygems'
require 'mini_exiftool'

# unless ARGV.size == 1
#   puts "usage: ruby #{__FILE__} URI"
#   puts " i.e.: ruby #{__FILE__} http://www.23hq.com/janfri/photo/1535332/large"
#   exit -1
# end

# Fetch an external photo
# filename = open(ARGV.first).path

filename = "/Users/gscar/Mylio/Mylio Main Library Folder/2024/OM-1-2024/2024.03.30-16.49.18.gs.O.orf"
photo = MiniExiftool.new filename

puts "\nAll EXIF data follows:\n"
begin
  puts ""
  photo.tags.sort.each do |tag|
    # puts "#{tag}:  #{photo[tag]}"
    puts tag.ljust(28) + photo[tag].to_s
  end
rescue Exception => e
  puts "(Tried to sort EXIF data alphabetically, but sometimes sort doesn't work so data below is not alphabetized.)\n\n"
  photo.tags.each do |tag|
    puts "#{tag}:  #{photo[tag]}"
  end
end

# Trying to dig into code but beyond m
# puts "\nOriginal Tags follows:\n"
# puts tags
# photo.tags.sort.each do |tag|
#   puts "#{tag}:  #{photo[tag]}"
# end

puts "\n==================================================="
puts "\nRunning in Command Line:\n"
result = system 'exiftool -a -u -g2 "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.30-16.49.18.gs.O.orf"'
puts "#{result}\n==================================================="

puts "\n-EXIF:CreateDate:\n"
system 'exiftool -EXIF:CreateDate  "/Users/gscar/2024.03.25-16.09.59.gs.O.orf"'
puts "==================================================="

puts "\n-EXIF:DriveMode ():\n"
system 'exiftool -EXIF:DriveMode "/Users/gscar/2024.03.25-16.09.59.gs.O.orf"'
puts "==================================================="

filename = "/Users/gscar/2024.03.25-16.09.59.gs.O.orf"
puts "\n-EXIF:DriveMode for #{filename}:\n"
system 'exiftool -EXIF:DriveMode "/Users/gscar/2024.03.25-16.09.59.gs.O.orf"'
puts "`DriveMode: Single Shot; Electronic shutter` is the result from command line"
puts "==================================================="

filename = "/Users/gscar/2024.03.25-16.09.59.gs.O.orf"
puts "\n-EXIF:DriveMode for #{filename}:\n"
system 'exiftool -EXIF:DriveMode "/Users/gscar/2024.03.25-16.09.59.gs.O.orf"'
puts "==================================================="