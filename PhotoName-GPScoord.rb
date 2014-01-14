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
require_relative 'lib/Photo_Naming_Pashua-SD2'
require_relative 'lib/Photo_Naming_Pashua–HD2'
require_relative 'lib/gpsYesPashua'

thisScript = File.dirname(__FILE__) +"/" # needed because the Pashua script calling a file seemed to need the directory. 
srcSDfolder = "/Volumes/NO NAME/DCIM/" # SD folder. Panasonic and probably Canon
srcHD = "/Volumes/Knobby Aperture II/_Download folder/ Drag Photos HERE/"  # Photos copied from original location such as camera or sent by others
sdFolderFile = thisScript + "currentData/SDfolder.txt" # shouldn't need full path
downloadsFolders = "/Volumes/Knobby Aperture II/_Download folder/"
destPhoto = downloadsFolders + "Latest Download/" #  These are relabeled and GPSed files.
destOrig  = downloadsFolders + "_already imported/" # folder to move originals to if not done in 
lastPhotoReadTextFile = thisScript + "currentData/lastPhotoRead.txt"
geoInfoMethod = "wikipedia" # for gpsPhoto to select georeferencing source. wikipedia—most general and osm—maybe better for cities
timeZonesFile = "lib/Greg camera time zones.yml"  


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

def whichOne(whichOne)
  if whichOne=="S"
    whichOne = "SD"
  else # Hard drive
    whichOne = "HD"
  end 
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

def copySD(src, srcHD, sdFolderFile, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) 
  # some of the above counter variables could be set at the beginning of this script and used locally
  puts "Begin Copying photos from SD card. List includes photos skipped."
  cardCount = 0
  cardCountCopied = 0
  doAgain = true # name isn't great, now means do it. A no doubt crude way to run back through the copy loop if we moved to another folder.
  timesThrough = 1 
  fileSDbasename = "" # got an error at puts fileSDbasename
  while doAgain==true # and timesThrough<=2 
    Dir.chdir(src) # needed for glob
    Dir.glob("P*") do |item| 
      cardCount += 1
      fn = src + item
      fnp = srcHD + "/" + item # using srcHD as the put files here place, might cause problems later
      # get filename and make select later than already downloaded
      fileSDbasename = File.basename(item,".*")
      # puts "78. #{cardCount}. item: #{item}. fileSDbasename: #{fileSDbasename}, fn: #{fn}"
      next if item == '.' or item == '..' or fileSDbasename <= lastPhotoFilename # don't need the first two with Dir.glob, but doesn't slow things down much overall for this script
      FileUtils.copy(fn, fnp) # Copy from card to hard drive. , preserve = true gives and error. But preserve also preserves permissions, so that may not be a good thing. If care will have to manually change creation date
      cardCountCopied += 1
    end # Dir.glob("P*") do |item| 
      # write the number of the last photo copied or moved
      # if fileSDbasename ends in 999, we need to move on to the next folder, and the while should allow another go around.
    doAgain = false
    if fileSDbasename[-3,3]=="999" # and NEXT PAIRED FILE DOES NOT EXIST, then can uncomment the two last lines of this if, but may also have to start the loop over, but it seems to be OK with mid calculation change.
        nextFolderNum = fileSDbasename[-7,3].to_i + 1 # getting first three digits of filename since that is also part of the folder name
        nextFolderName = nextFolderNum.to_s + "_PANA"
        begin
          # Writing which folder we're now in
          fileNow = File.open(thisScript + sdFolderFile, "w")
          fileNow.write(nextFolderName) 
        rescue IOError => e
          puts "Something went wrong. Could not write last photo read (#{nextFolderName}) to #{sdFolderFile}"
        ensure
            fileNow.close unless fileNow == nil
        end # begin writing sdFolderFile
        # puts "\n#{nextFolderName} File.exist?(nextFolderName): #{File.exist?(nextFolderName)}" 
        src = srcSDfolder + nextFolderName + "/"
        if File.exist?(src)
          doAgain = true
        else
          doAgain = false
        end     
        puts "Moving to #{src} because the folder we started in was full.\n"
    end
  end # if doAgain…
  # Writing which file on the card we ended on
  begin
      fileNow = File.open(lastPhotoReadTextFile, "w") # must use explicit path, otherwise will use wherever we are are on the SD card
      fileNow.puts fileSDbasename
      fileNow.close
      puts "\n495. The last file processed. fileSDbasename, #{fileSDbasename}, written to  #{fileSDbasename}."
  rescue IOError => e
    puts "Something went wrong. Could not write last photo read (#{fileSDbasename}) to #{fileNow}"
  end # begin
    puts "\n116. Of the #{cardCount} photos on the SD card, #{cardCountCopied} were copied." # Could get rid of the and with an if somewhere since only copying or moving is done.
    puts "117. Done copying photos from SD card. src switched from card to folder holder moved or copied photos: #{src}"  
end # copySD

def copyAndMove(srcHD,destPhoto,destOrig)
  puts "First will copy to the final destination where the renaming will be done and the original moved to an archive (already imported folder)"
  #  Only copy jpg to destPhoto if there is not a corresponding raw, but keep all taken files. With Panasonic JPG comes before RW2
  photoFinalCount = 0
  Dir.foreach(srcHD) do |item| 
    next if item == '.' or item == '..' or item == '.DS_Store' 
    fileExt = File.extname(item)
    if File.basename(itemPrev, ".*") == File.basename(item,".*")
     #  The following shouldn't be necessary, but is a check in case another kind of raw or who know what else. Only the FileUtils.rm(itemPrev) should be needed
     if File.extname(itemPrev) ==".JPG"
        FileUtils.rm(fnp)
        photoFinalCount -= 1
      else
        puts "xx. Something very wrong here with trying to remove JPGs when there is a corresponding .RW2"
      end    
    end
    fn  = srcHD     + item # sourced from Drag Photos Here
    fnp = destPhoto + item # new file in Latest Download
    fnf = destOrig  + item # to already imported
    FileUtils.copy(fn, fnp)
    FileUtils.move(fn, fnf)
    itemPrev = item
    photoFinalCount += 1
  end  
  puts "148. photoFinalCount: #{photoFinalCount} photos have been moved and are ready for renaming and gpsing"
end


# With the fileDateUTC for the photo, find the time zone based on the log.
# The log is in numerical order and used as index here. The log is a YAML file
def timeZone(fileDateUTC, timeZonesFile)
  # theTimeAhead = "2050-01-01T00:00:00Z"
  # puts "379. timeZonesFile: #{timeZonesFile}. "
  timeZones = YAML.load(File.read(timeZonesFile)) # should we do this once somewhere else?
  i = timeZones.keys.max # e.g. 505
  j = timeZones.keys.min # e.g. 488
  while i > j # make sure I really get to the end 
    theTime = timeZones[i]["timeGMT"]
    # puts "\nA. i: #{i}. theTime: #{theTime}" # i: 502. theTime: 2011-06-29T01-00-00Z
    theTime = Time.parse(theTime) # class: time Wed Jun 29 00:00:00 -0700 2011
    # puts "\nB. #{i}. fileDateUTC: #{fileDateUTC}. theTime: #{theTime}. fileDateUTC.class: #{theTime.class}. fileDateUTC.class: #{theTime.class}"
    # puts "Note that these dates are supposed to be UTC, but are getting my local time zone attached."
    if fileDateUTC>theTime
      theTimeZone = timeZones[i]["zone"]
      # puts "C. #{i}. fileDateUTC: #{fileDateUTC} fileDateUTC.class: #{fileDateUTC.class}. theTimeZone: #{theTimeZone}."
      return theTimeZone
    else
      i= (i.to_i-1).to_s
    end
  end # loop
  # puts "D. #{i}. fileDateUTC: #{fileDateUTC} fileDateUTC.class: #{fileDateUTC.class}. theTimeZone: #{theTimeZone}. "
  return theTimeZone
end # timeZone


## The "program" #################
puts "Fine naming and moving started: #{Time.now}" # for trial runs
srcSD = srcSDfolder + sdFolder(sdFolderFile)

# Ask whether working with photo files from SD card or HD
fromWhere = whichLoc() # This is pulling in first Pashua window (1. ), SDorHD.rb which has been required
whichDrive = fromWhere["whichDrive"][0].chr # only using the first character
puts "whichDrive: #{whichDrive}"
# Set the return into a more friendly variable and set the src of the photos to be processed
whichOne = whichOne(whichDrive) # parsing result to get HD or SD
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
  prefsPhoto = pPashua2(src,lastPhotoFilename,destPhoto,destOrig) # calling Photo_Handling_Pashua-SD
  # to get a value use prefsPhoto("theNameInFileNamingEtcPashue.rb"), nothing to do with the name above
  # puts "Prefs as set by pPashua"
  # prefsPhoto.each {|key,value| puts "#{key}:       #{value}"}
  src = prefsPhoto["srcSelect"]  + "/"
  lastPhotoFilename = prefsPhoto["lastPhoto"]
  destPhoto = prefsPhoto["destPhotoP"]
  destOrig  = prefsPhoto["destOrig"]
else # whichOne=="HD", but what
  src = srcHD
  prefsPhoto = pGUI(src, destPhoto, destOrig) # is this only sending values in? 
  # to get a value use prefsPhoto("theNameInFileNamingEtcPashue.rb"), nothing to do with the name above
  # puts "Prefs as set by pGUI"
  # prefsPhoto.each {|key,value| puts "#{key}:       #{value}"}
  src = prefsPhoto["srcSelect"]  + "/"
  destPhoto = prefsPhoto["destPhotoP"]
  destOrig  = prefsPhoto["destOrig"]
end # whichOne=="SD"

puts "\nIntialization and complete. File renaming and copying/moving beginning..."

#  If working from SD card, copy or move files to " Drag Photos HERE Drag Photos HERE" folder, then will process from there.
copySD(src, srcHD, sdFolderFile, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) if whichOne == "SD"
#  Note that file creation date is the time of copying. May want to fix this. Maybe a mv is a copy and move which is sort of a recreation. 

# src = srcHD # switching since next part works from copied files on hard drive. 

puts "\n 170. Photos will now be copied and renamed. \n........Using #{geoInfoMethod} as a source, GPS information will be added to photos..........\n"

puts "First will copy to the final destination where the renaming will be done and the original moved to an archive (already imported folder)"
#  Only copy jpg to destPhoto if there is not a corresponding raw, but keep all taken files. With Panasonic JPG comes before RW2
copyAndMove(srcHD,destPhoto,destOrig)
