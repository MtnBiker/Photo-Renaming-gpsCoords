#!/usr/bin/env ruby
# incomplete and doesn't maybe work, but need further testing, Was using in wrong folder
# system ('gem env') # for debugging problem with gem not loading https://stackoverflow.com/questions/53202164/textmate-chruby-and-ruby-gems
# puts "\nGem.path: #{Gem.path}"
require 'fileutils'
include FileUtils
require 'find'
require 'mini_exiftool' # PATH in TM to $PATH:/usr/local/bin for exiftool to be seen (careful easy to mix mini_exiftool and exiftool issues)

def lineNum()
  caller_infos = caller.first.split(":")
  # Note caller_infos[0] is file name
  caller_infos[1]
end # line numbers of this file, useful for debugging and logging info to progress screen

puts "#{lineNum}. Starting script"

# The mp4 file
fnMp4 = "/Volumes/Seagate 8TB Backup/Mylio_87103a/2019 Baja/2019.03.22-09.02.59.gs.P.mp4"
fileEXIFmp4 = MiniExiftool.new(fnMp4)

puts "#{lineNum}: fnMp4: #{fnMp4}"
fileDirectory = fileEXIFmp4.Directory
fileName = File.basename(fnMp4) # f fileEXIFmp4.FileName didn't work

fnJpg = fnMp4 + '.jpg' # create from file
fnJpg = fnMp4 + '.png' # create from file
# fnJpg = "/Volumes/Seagate 8TB Backup/Mylio_87103a/2019 Baja/NE Isla Carmen. Salt flat.png"

puts "#{lineNum}. fnJpg: #{fnJpg}"


# fnJpg = fnMp4 + '.png' # create from file
# fnJpg = fileEXIFmp4.directory.to_s + "/" + fileEXIFmp4.FileName.to_s + ".png" # didn't work?
fileEXIFjpg = MiniExiftool.new(fnJpg)

# fileEXIFjpg.model = fileEXIFmp4.model # sample
# puts "#{lineNum}. fileEXIFmp4.source: #{fileEXIFmp4.source}"
fileEXIFjpg.source = "One frame of #{fileName} (#{fileEXIFmp4.source})"
# puts "#{lineNum}. fileEXIFjpg.source: #{fileEXIFjpg.source}. This isn't getting written to jpgygu for some reason!"
fileEXIFjpg.make =  fileEXIFmp4.make
fileEXIFjpg.model = fileEXIFmp4.model
fileEXIFjpg.DateTimeOriginal = fileEXIFmp4.dateTimeOriginal
fileEXIFjpg.CreateDate       = fileEXIFmp4.CreateDate # TrackCreateDate is different from CreateDate, maybe copy to hard drive date
# fileEXIFjpg.TimeStamp =  fileEXIFmp4.TimeStamp # Doesn't work, i.e., value doesn't get written and stops other values from being update SOMETIMES
# fileEXIFjpg.ModifyDate       = fileEXIFmp4.ModifyDate
# fileEXIFjpg.LensID   =   fileEXIFmp4.LensID  # Doesn't work  , i.e., value doesn't get written and stops other values from being update
# fileEXIFjpg.FOV      =   fileEXIFmp4.FOV     # Doesn't work  , i.e., value doesn't get written and stops other values from being update
fileEXIFjpg.Location =   fileEXIFmp4.Location if fileEXIFmp4.Location?
fileEXIFjpg.Country =    fileEXIFmp4.Country if fileEXIFmp4.Country?
fileEXIFjpg.State  =     fileEXIFmp4.State if fileEXIFmp4.State?
fileEXIFjpg.City  =      fileEXIFmp4.City if fileEXIFmp4.City?
fileEXIFjpg.instructions = "One frame of #{fileName} and EXIF copied in part from that mp4"
puts "#{lineNum}. fileEXIFjpg.CreateDate: #{fileEXIFjpg.CreateDate}"
puts "#{lineNum}. fileEXIFjpg.Instructions: #{fileEXIFjpg.Instructions}"
begin # because nothing happening with save, but no errors
  whatHappened = fileEXIFjpg.save
  puts "#{lineNum}. whatHappened: #{whatHappened}. true is supposed to be it worked, but not working for me."
  puts "#{lineNum}. saving and seeing if error generated even though when I wrote this line, nothing was saved to file"
rescue MiniExiftool::Error => e
    $stderr.puts e.message
end


# Test since not working right
# fileEXIFreadback = MiniExiftool.new(fnJpg)
# if fileEXIFreadback.CreateDate?
#   puts "#{lineNum}. Checking. fileEXIFreadback.CreateDate:#{fileEXIFreadback.CreateDate}"
# else
#   puts "EXIF data not written and why not? Argh!"
# end

# Spit out the new exiftool results
puts "\n#{lineNum}. Reading back the photo with the mp4 info? #{fnJpg}"
photo = fileEXIFjpg
begin
  # puts ""
  photo.tags.sort.each do |tag|
    puts tag.ljust(28) + photo[tag].to_s
  end
rescue Exception => e
  puts "(Tried to sort EXIF data alphabetically, but sometimes sort doesn't work so data below is not alphabetized.)\n\n"
  photo.tags.each do |tag|
    puts "#{tag}:  #{photo[tag]}"
  end
end
