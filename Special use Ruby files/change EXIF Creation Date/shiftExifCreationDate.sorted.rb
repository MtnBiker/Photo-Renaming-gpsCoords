#!/usr/bin/env ruby

# Works for single file or directory. 
# Caution: original file is being changed
# Mylio picks up the changes.

# Quit Mylio
# Move files into a temp directory
# Run this script
# Move files back into Mylio folder
# Relaunch Mylio

# Based on my changeExifCreationDate.sorted.rb

# Must set these variables manually. Next five lines
src = "//Users/gscar/Mylio/2022/GX8-2022/temp/"
src = "/Users/gscar/Mylio/Mylio Main Library Folder/2018/Rich bike ride/"

# Seconds to add to existing time of photo, i.e. move to future 2:31 = 151
delta = -151
delta = (57*60)+28

require 'mini_exiftool'

# The script. Shouldn't have to make changes on any of the lines below
count = 0

# useful for debugging and logging info to progress screen
def lineNum()
  caller_infos = caller.first.split(":")
  # Note caller_infos[0] is file name
  # caller_infos[1]
  return "Line no. #{caller_infos[1]}"
end 

if File.file?(src) # single file. true if file, false otherwise such as a directory. Really shouldn't need this, but I based this on an earlier script where I did need it
  puts "#{lineNum}. One photo in #{src} will be processed. #{File.file?(src)}"
  fn = src # long file name. So can use what I have for directory
  fileEXIF = MiniExiftool.new(fn)
  originalDateTime = fileEXIF.CreateDate
  puts "\n#{lineNum}. #{src}. originalDateTime: #{originalDateTime}" # Create Date : 2022:04:19 07:28:33.009 or  2022:04:19 12:33:22-07:00
  shiftedDate = originalDateTime + delta
  date = shiftedDate # reusing var from directories
  fileEXIF = MiniExiftool.new(fn)
  fileEXIF.CreateDate = date
  fileEXIF.DateTimeOriginal = date
  fileEXIF.save
  # puts "\n#{lineNum}. #{item} dates changed to #{date}"
  fileEXIFread = MiniExiftool.new(fn)
  readBackDate = fileEXIFread.DateTimeOriginal
  fileEXIFread.save
  puts "\n#{lineNum}. #{src}. was: #{originalDateTime}. Shifted to: #{readBackDate}"
  count = 1
else # a whole directory
  # https://stackoverflow.com/questions/5480703/how-to-sort-an-alphanumeric-array-in-ruby
  puts "Files in #{src} will be processed. PDFs and XMPs will (can)not be processed.\n\n"
  Dir.chdir(src)
  files = Dir.glob("*.{jpg,png,rw2}")  # Restricts to only this type of file.
  files.each do |file|
    fn = src + file # long file name
    fileEXIF = MiniExiftool.new(fn)
    originalDateTime = fileEXIF.CreateDate
    # puts "\n#{lineNum}. #{src}. originalDateTime: #{originalDateTime}" # Create Date : 2022:04:19 07:28:33.009 or  2022:04:19 12:33:22-07:00
    shiftedDate = originalDateTime + delta
    date = shiftedDate # reusing var from directories
    fileEXIF.CreateDate = date
    fileEXIF.DateTimeOriginal = date
    fileEXIF.save
    # puts "\n#{lineNum}. #{item} dates changed to #{date}"
    fileEXIFread = MiniExiftool.new(fn)
    readBackDate = fileEXIFread.DateTimeOriginal
    fileEXIFread.save
    count += 1
    puts "\n#{count}. #{src}.\n.     was: #{originalDateTime}. \nShifted to: #{readBackDate}"
  end 
end

if count > 0
  puts "\n#{count} files processed in folder #{src}."
else
  puts "\n XXXXXX  NO FILES PROCESSED. COUNT WAS #{count}.  XXXXXXXXXX"
end
