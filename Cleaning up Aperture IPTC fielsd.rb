#!/usr/bin/env ruby
require 'mini_exiftool'
require 'find'

# dir = /Volumes/Knobby Aperture Two/Aperture Libraries/Knobby 2008++Sierra.aplibrary/
#  for now use a copy or sample
src = "/Users/gscar/Documents/◊ Pre-trash/Onion Valley 2015 Test.aplibrary/Masters/"
i = 0

def ignoreNonFiles(item) # invisible files that shouldn't be processed
  item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon ' or File.directory?(item)
  # This is true when it should not be processed i.e. next if ignoreNonFiles(item) == true
end

# Dir.glob("#{src}/*.{jpg,rw2,jpeg}") do |item|
# Dir.glob('/Users/gscar/Documents/◊ Pre-trash/Onion Valley 2015 Test.aplibrary/Masters/') do |item|
# Dir.foreach(src) do |item|
#
# Dir.glob('/Users/gscar/Documents/◊ Pre-trash/Onion Valley 2015 Test.aplibrary/Masters/*.{jpg,rw2,jpeg}') do |item|

Find.find(src) do |item|
  i += 1
  next if ignoreNonFiles(item) == true # skipping file when true
  puts "\n#{i}. #{item}"

  fileEXIF = MiniExiftool.new(item)

# Moving title to source. This works
  if fileEXIF.title.to_s.length > 2 # in other words if it exists
    fileEXIF.source = fileEXIF.title
  end

  # puts fileEXIF.description
  # Write Caption to Title. Not working—confirm that Caption is Caption. Apparently it's not
  if fileEXIF.caption.to_s.length > 2
    fileEXIF.title = fileEXIF.caption
    puts "#{i}. #{item}. Writing Caption to Title"
  else
    fileEXIF.title = "" # to wipe out the old filename that was there
    puts "#{i}. #{item}. Writing blank to Title"
  end
  fileEXIF.save
end
