#!/usr/bin/env ruby
# Refactored new version 2013.12.10

require 'rubygems' # # Needed by rbosa, mini_exiftool, and maybe by appscript. Not needed if correct path set somewhere.
require 'mini_exiftool' # Requires Ruby ≥1.9. A wrapper for the Perl ExifTool
require 'fileutils'
include FileUtils
require 'find'
require 'yaml'
require "time"

require_relative 'lib/SDorHD'
require_relative 'lib/Photo_Naming_Pashua-SD'
require_relative 'lib/Photo_Naming_Pashua–HD'
require_relative 'lib/gpsYesPashua'

thisScript = File.dirname(__FILE__) +"/" # needed because the Pashua script calling a file seemed to need the directory. 
srcSDfolder = "/Volumes/NO NAME/DCIM/" # SD folder. Panasonic and probably Canon
srcHD = "/Volumes/Knobby Aperture II/_Download folder/ Drag Photos HERE/"  # Photos copied from original location such as camera or sent by others
sdFolderFile = thisScript + "currentData/SDfolder.txt" # shouldn't need full path
downloadsFolders = "/Volumes/Knobby Aperture II/_Download folder/"
destPhoto = downloadsFolders + "Latest Download/" #  These are relabeled and GPSed files.
destOrig  = downloadsFolders + "_already imported/" # folder to move originals to if not done in 
lastPhotoReadTextFile = thisScript + "currentData/lastPhotoRead.txt"

puts "RUBY_DESCRIPTION: #{RUBY_DESCRIPTION}\n\n" 

class Photo
  
end

def sdFolder(sdFolderFile)  
  begin
    file = File.new(sdFolderFile, "r")
    sdFolder = file.gets
    file.close
  rescue Exception => err
    puts "Exception: #{err}. Could not read which folder is current on the SD card from #{sdFolderFile}"
  end
  sdFolder
end

def whichOne(whereFrom)
  whichOne = whereFrom["whichDrive"][0].chr # only using the first character
  if whichOne=="S"
    whichOne = "SD"
    whichOneLong = " a plugged in SD card."
  else # Hard drive
    whichOne = "HD"
    whichOneLong = whichOneLong + " a folder on a hard drive."
  end # whichOne=="S"
  whichOne  
end

def whichSource(whichOne,prefsPhoto)
  case whichOne
  when SD
    src = prefsPhoto["srcSelect"]  + "/"
  when HD
    src = prefsPhoto["srcSelect"]  + "/"
  end
  src
end

## The "program" #################
puts "Fine naming and moving started: #{Time.now}" # for trial runs
srcSD = srcSDfolder + sdFolder(sdFolderFile)

# Ask whether working with photo files from SD card or HD
fromWhere = whichLoc() # This is pulling in first Pashua window (1. ), SDorHD.rb which has been required
puts "fromWhere: #{fromWhere}"
# Set the return into a more friendly variable and set the src of the photos to be processed
whichOne = whichOne(fromWhere) # parsing result to get HD or SD
if whichOne=="SD" # otherwise it's HD, probably should be case to be cleaner coding
  # read in last filename copied from card previously
  begin
    file = File.new(lastPhotoReadTextFile, "r")
    lastPhotoFilename = file.gets # apparently grabbing a return. maybe not the best reading method.
    puts "540. lastPhotoFilename: #{lastPhotoFilename}. Read from #{lastPhotoReadTextFile}. Value can be changed by user, so this may not be the final value."
    file.close
  rescue Exception => err
    puts "Exception: #{err}. Not critical as value can be entered manually by user."
  end
  src = srcSD
  prefsPhoto = pPashua(src,lastPhotoFilename,destPhoto,destOrig) # calling Photo_Handling_Pashua-SD
  # to get a value use prefsPhoto("theNameInFileNamingEtcPashue.rb"), nothing to do with the name above
  # puts "Prefs as set by pPashua"
  # prefsPhoto.each {|key,value| puts "#{key}:       #{value}"}
  src = prefsPhoto["srcSelect"]  + "/"
  lastPhotoFilename = prefsPhoto["lastPhoto"]
  destPhoto = prefsPhoto["destPhotoP"]
  destOrig  = prefsPhoto["destOrig"]
  photoHandling = prefsPhoto["photoHandle"][0].chr # only using the first character 
else # whichOne=="HD"
  src = srcHD
  prefsPhoto = pGUI(src, destPhoto, photoHandling, destOrig,geoOnly) # is this only sending values in? 
  # to get a value use prefsPhoto("theNameInFileNamingEtcPashue.rb"), nothing to do with the name above
  # puts "Prefs as set by pGUI"
  # prefsPhoto.each {|key,value| puts "#{key}:       #{value}"}
  src = prefsPhoto["srcSelect"]  + "/"
  destPhoto = prefsPhoto["destPhotoP"]
  destOrig  = prefsPhoto["destOrig"]
  photoHandling = prefsPhoto["photoHandle"][0].chr # only using the first character 
  photoHandling = "A"  # since options not given, but could add back in
  case prefsPhoto["geoOnly"]
   when "1"
     geoOnly = true
  when "0"
    geoOnly = false
  else puts "We've got a problem determining geoOnly"
  end
end # whichOne=="SD"

