#!/usr/bin/env ruby

# Works for single file or directory. 
# Caution: original file is being changed
# Mylio picks up the changes.

# ## For more than one directory in a year and both are Jan 1. Make the second one Jan 2, and the third Jan 3, so they sort better in Mylio

# Must set these variables manually. Next five lines
# src = "/Users/gscar/Pictures/Epson V600 scans/" # Keeping as a frequently used folder
src = "/Users/gscar/Mylio/Mylio Main Library Folder/2017/2017.04.19.Bronzeville.png"
# Making it easier (less error prone) to change the date

year = "2017" # 1898
month =  "04" # 01
day =    "19" # 01

# date_partial = "1881:01:01:01 00:00:00" # Could change back to date and get line 39 to date.next!
date_partial = "#{year}:#{month}:#{day} 00:00:00" # Time set is UTC relative to here, slightly better if could make midnight UTC FIXME
# date_partial = "2021.09.26-14.05.00" # From Mylio. Copy file name, change . to : and  - to space

require 'mini_exiftool'
require 'naturally' # for natural sort https://github.com/dogweather/naturally
# require 'pathname' # Tried using but got messed up because an object, not a path

# MANUALLY. Sometimes easier. Format: "1909:01:01 00:00:00"
# date_partial = "2021:07:15 11:56:07" 

# The script. Shouldn't have to make changes on any of the lines below
count = 0

# useful for debugging and logging info to progress screen
def lineNum()
  caller_infos = caller.first.split(":")
  # Note caller_infos[0] is file name
  # caller_infos[1]
  return "Line no. #{caller_infos[1]}"
end 
# def ignoreNonFiles(item) # invisible files that shouldn't be processed including pdf and xmp. Not using this now
#   item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon ' or item.slice(0,7) == ".MYLock" or item.end_with?("xmp") or  item.end_with?("pdf")
# end

if File.file?(src) # single file. true if file, false otherwise such as a directory
  puts "#{lineNum}. One photo in #{src} will be processed. #{File.file?(src)}"
  fn = src # long file name. So can use what I have for dirctory
  date = date_partial # reusing var from directories
  fileEXIF = MiniExiftool.new(fn)
  fileEXIF.CreateDate = date
  fileEXIF.DateTimeOriginal = date
  fileEXIF.save
  # puts "\n#{lineNum}. #{item} dates changed to #{date}"
  fileEXIFread = MiniExiftool.new(fn)
  readBackDate = fileEXIFread.DateTimeOriginal
  fileEXIFread.save
  puts "\n#{lineNum}. #{src}. readBackDate: #{readBackDate}"
  count = 1
else # a whole directory
  # https://stackoverflow.com/questions/5480703/how-to-sort-an-alphanumeric-array-in-ruby
  puts "Files in #{src} will be processed. PDFs and XMPs will (can)not be processed.\n\n"
  Dir.chdir(src)
  files = Dir.glob("*.{jpg,png}")  # Restricts to only this type of file.
  # puts "#{lineNum}. files: #{files}"
  # Files for crores are named in page order, and this sorts them in this order, and the new dates are increased by 1 sec per file so they show up in page order in Mylio
  filesSorted = Naturally.sort(files)
  # puts "#{lineNum}. files after sort: #{filesSorted}"
  filesSorted.each do |file|
    fn = src + file # long file name
    fileEXIF = MiniExiftool.new(fn)
    # Need to index the date by a minute, so may need to make sure it's date and not text
    if count < 100
      date = date_partial.next!
      count += 1
    end # count

    fileEXIF.CreateDate = date
    fileEXIF.DateTimeOriginal = date
    fileEXIF.save
    # puts "\n#{lineNum}. #{item} dates changed to #{date}"
    fileEXIFread = MiniExiftool.new(fn)
    readBackDate = fileEXIFread.DateTimeOriginal
    fileEXIFread.save
    puts  "#{count}. #{file}. readBackDate: #{readBackDate}"
  end # filesSorted.each or  Naturally.sort(files).each
end

if count > 0
  puts "\n#{count} files processed in folder #{src}."
else
  puts "\n XXXXXX  NO FILES PROCESSED. COUNT WAS #{count}.  XXXXXXXXXX"
end
