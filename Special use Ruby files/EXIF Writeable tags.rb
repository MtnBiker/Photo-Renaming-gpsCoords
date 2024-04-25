#!/usr/bin/env ruby
ENV['PATH'] = '/opt/homebrew/bin:' + ENV['PATH'] # I think this is in 
require 'rubygems' # # Needed by rbosa, mini_exiftool, and maybe by appscript,  
require 'mini_exiftool' # a wrapper for the Perl ExifTool 
#require 'time'
#require 'fileutils'
#include fileutils
#require 'find'
#  Created by Greg Scarich on 2007-07-11.  Copyright (©) 2007. All rights reserved.


# fn = "/Volumes/Daguerre/_Download folder/Latest Processed photos-Import to Mylio/2019.08.05-10.49.54.gs.P.jpg"
fn = "/Volumes/Daguerre/_Download folder/_imported-archive/0100-OM-1/O4223929.JPG" # Straight from camera
fn = "/Volumes/Daguerre/_Download folder/ Drag Photos HERE/P1230782.RW2"
tagCount = 0 # existing
totalTagCount = 0 # could exist
puts "Tags with data? MiniExiftool tags for #{fn}"
puts
tagArray = MiniExiftool.new(fn)

# Only tags with data or all tags
MiniExiftool.writable_tags.sort.each do |tag|
  if tagArray[tag]
    puts "#{tag}:         #{tagArray[tag]}"
    tagCount += 1
  else
    # puts "#{tag}. Empty or ?"
  end
  totalTagCount += 1
end

# Too see all tags
# MiniExiftool.writable_tags.sort.each do |tag|
#   puts "#{tag}:         #{tagArray[tag]}"
#   tagCount += 1
# end


puts
# puts "Always says 1637 tags, so maybe can't write to all formats (movies, MRW),"
# puts "probably just what MiniExiftools know about. Try it"
puts "#{__LINE__}. #{tagCount} tags written for #{totalTagCount} possible tags for this file #{fn}" 
puts "Extension:  #{File.extname(fn)}"
puts "FileType:    #{tagArray.FileType(fn)}"
puts "MIMEType:    #{tagArray.MIMEType}"

