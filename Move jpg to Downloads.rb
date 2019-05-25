#!/usr/bin/env ruby
# Moving jpgs back to " Drag Photos HERE/" folder to be processed. Shouldn't be needed now.

require 'find'
require 'fileutils'
include FileUtils

def lineNum()
  caller_infos = caller.first.split(":")
  # Note caller_infos[0] is file name
  caller_infos[1]
end # line numbers of this file, useful for debugging and logging info to progress screen

baseFolder = "/Volumes/Daguerre/_Download folder/" # May vary for testing
# baseFolder = "/Users/gscar/Documents/◊ Pre-trash/testJPGsort/" # a test folder. Populated with mixed jpg and rw2 and another folder
archiveFolder = baseFolder + "_imported-archive/" # After first go through all file will be here 
downloadsFolderDrag = baseFolder +" Drag Photos HERE/"
# Find.find(folder) do |fn|
Dir.entries(archiveFolder).sort.each do |item| # This construct goes through each in order. Sometimes the files are not in order with Dir.foreach or Dir.entries without sort
  # next if item == '.' or item == '..' or item == '.DS_Store' # This didn't work for some reason
  fn = archiveFolder + "/" + item
  fnp = downloadsFolderDrag + "/" + item
  if item == '.DS_Store'
    puts "#{lineNum}. item: #{item}. File.file?(item): #{File.file?(item)}"
  else
     if File.file?(fn) # no diving into folders
      fileExt = File.extname(fn).tr(".","").downcase
      # puts "#{lineNum}. fileExt: #{fileExt}"
        if fileExt == "jpg"
         FileUtils.move(fn, fnp)
         puts "#{lineNum}. #{fn} was moved to #{fnp} because it's a jpg"
        else # not a jpg
         puts "#{lineNum}. #{fn} was skipped because it's not a jpg"
        end # if fileExt
     end # if File.file?    
  end # if item
end # Dir.entries

