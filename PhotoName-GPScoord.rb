#!/usr/bin/env ruby
# Refactored new version 2013.12.10

require 'rubygems' # # Needed by rbosa, mini_exiftool, and maybe by appscript. Not needed if correct path set somewhere.
require 'mini_exiftool' # Requires Ruby ≥1.9. A wrapper for the Perl ExifTool
require 'fileutils'
include FileUtils
require 'find'
require 'yaml'
require "time"
require 'shellwords'

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
timeZonesFile = "/Users/gscar/Dropbox/scriptsEtc/Greg camera time zones.yml"
timeZones = YAML.load(File.read(timeZonesFile)) # read in that file now and get it over with
gpsPhotoPerl = "lib/gpsPhoto.pl" # Perl script that puts gps locations into the photos. SEEMS TO WORK WITHOUT ./lib
gpsPhotoPerl = "/Users/gscar/Documents/Ruby/Photo handling/lib/gpsPhoto.pl"
folderGPX = "/Users/gscar/Dropbox/   GPX daily logs/2014 Download/" # Could make it smarter, so it knows which year it is. 



puts "RUBY_DESCRIPTION: #{RUBY_DESCRIPTION}\n\n" 

class Photo
  
end

def timeStamp(timeNowWas)
  puts "#{(Time.now-timeNowWas).to_i} seconds. #{Time.now.strftime("%I:%M:%S %p")}"
  timeNowWas = Time.now
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
  puts "\n72. Copying photos from an SD card"
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
      puts "\n127. The last file processed. fileSDbasename, #{fileSDbasename}, written to  #{fileSDbasename}."
  rescue IOError => e
    puts "Something went wrong. Could not write last photo read (#{fileSDbasename}) to #{fileNow}"
  end # begin
    puts "\n131. Of the #{cardCount} photos on the SD card, #{cardCountCopied} were copied" # Could get rid of the and with an if somewhere since only copying or moving is done.
    # puts "125. Done copying photos from SD card. src switched from card to folder holder moved or copied photos: #{src}"  
end # copySD

def copyAndMove(srcHD,destPhoto,destOrig)
  puts "First will copy to the final destination where the renaming will be done and the original moved to an archive (already imported folder)"
  #  Only copy jpg to destPhoto if there is not a corresponding raw, but keep all taken files. With Panasonic JPG comes before RW2
  # THIS METHOD WILL NOT WORK IF THE RAW FILE FORMAT ALPHABETICALLY COMES BEFORE JPG. SHOULD MAKE THIS MORE ROBUST
  photoFinalCount = 0
  delCount = 1
  itemPrev = "" # need something for first time through
  fnp = "" # when looped back got error "undefined local variable or method ‘fnp’ for main:Object", so needs to be set here to remember it. Yes, this works, without this statement get an error 
  Dir.foreach(srcHD) do |item| 
    # puts "131.. photoFinalCount: #{photoFinalCount + 1}. item: #{item}."
    next if item == '.' or item == '..' or item == '.DS_Store' 
    fileExt = File.extname(item)
    if File.basename(itemPrev, ".*") == File.basename(item,".*") && photoFinalCount != 0
     #  The following shouldn't be necessary, but is a check in case another kind of raw or who know what else. Only the FileUtils.rm(itemPrev) should be needed
     # puts "136.. itemPrev: #{itemPrev}"
     if File.extname(itemPrev) ==".JPG"
       FileUtils.rm(fnp)
       # puts "145. #{delCount}. fnp: #{itemPrev} will not be transferred because it's a duplicate jpg." # Is this slow? Turned off to try. Not sure.
       delCount += 1
       photoFinalCount -= 1
      else
        puts "149. Something very wrong here with trying to remove JPGs when there is a corresponding .RW2"
      end # File.extname  
    end   # File.basename
    fn  = srcHD     + item # sourced from Drag Photos Here
    fnp = destPhoto + item # new file in Latest Download
    # puts "147.. fnp: #{fnp}"
    fnf = destOrig  + item # to already imported
    FileUtils.copy(fn, fnp)
    FileUtils.move(fn, fnf)
    itemPrev = item
    photoFinalCount += 1
  end # Dir.foreach
  puts "\n158. #{photoFinalCount} photos have been moved and are ready for renaming and gpsing. #{delCount-1} duplicate jpg were not moved."
end # copyAndMove: copy to the final destination where the renaming will be done and the original moved to an archive (already imported folder)

def userCamCode(fn)
  fileEXIF = MiniExiftool.new(fn)
  ## not very well thought out and the order of the tests matters
  case fileEXIF.model
  when "DMC-G2"
    userCamCode = ".gs.L" # gs for photographer. L for Panasonic *L*umix
  when "Canon PowerShot S100"
    userCamCode = ".lb" # initials of the photographer who usually shoots with the S100
  else
    userCamCode = ".xx"
  end # case
  if fileEXIF.fileType(fn) == "??"
    userCamCode = ".gs.L"
  end
  if fileEXIF.fileType(fn) == "AVI" # is this for Canon video ?
    userCamCode = ".lb.c"
  end
  return userCamCode
end # userCamCode

def fileAnnotate(fn, fileEXIF, fileDateUTCstr, tzoLoc)  # writing original filename and dateTimeOrig to the photo file.
  # writing original filename and dateTimeOrig to the photo file.
  # ---- XMP-photoshop: Instructions  May not need, but it does show up if look at all EXIF, but not sure can see it in Aperture
  # Comment shows up in Aperture as  
  # fileEXIF = MiniExiftool.new(fn)
  if fileEXIF.comment.to_s.length < 2 # if exists then don't write. If avoid rewriting, then can eliminate this test
    # fileEXIF.comment = fileEXIF.instructions = "Original filename: #{File.basename(fn)} and date: #{fileDateUTCstr} UTC. Time zone of photo is GMT #{tzoLoc}" # This works, next line is testing returns in the EXIF 
    fileEXIF.comment = fileEXIF.instructions = "Original filename: #{File.basename(fn)}. Capture date: #{fileDateUTCstr} UTC. Time zone of photo is GMT #{tzoLoc}"
    
    fileEXIF.save
  end
end # fileAnnotate. writing original filename and dateTimeOrig to the photo file.

# With the fileDateUTC for the photo, find the time zone based on the log.
# The log is in numerical order and used as index here. The log is a YAML file
def timeZone(fileDateUTC, timeZones)
  # theTimeAhead = "2050-01-01T00:00:00Z"
  # puts "379. timeZonesFile: #{timeZonesFile}. "
  # timeZones = YAML.load(File.read(timeZonesFile)) # should we do this once somewhere else? Let's try that in this new version
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

def rename(src, timeZonesFile)
  # Dir.chdir(thisScript) # otherwise didn't know where it was to find folderGPX since used a chdir elsewhere in the script
  fileDatePrev = ""
  dupCount = 0
  seqLetter = %w(a b c d e f g h i) # seems like this should be an array, not a list
  Dir.foreach(src) do |item| 
    next if item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon ' # There is a space after Icon . This doesn't skip Icon as it should tries to process the file which results in an error. Also this Icon file is seen as a file, so can't use ftype so sort. I removed the icon, I guess I could have set up and error trap or maybe tried file type later in this process
    fn = src + item
       # puts "\n709. #{fileCount}. fn: #{fn}"
    # puts "230.. File.file?(fn): #{File.file?(fn)}"
    if File.file?(fn) # 
      # Determine the time and time zone where the photo was taken
      # puts "233.. fn: #{fn}. File.ftype(fn): #{File.ftype(fn)}"
      fileEXIF = MiniExiftool.new(fn)
      fileDateUTC = fileEXIF.dateTimeOriginal # class time, but adds the local time zone to the result although it is really UTC (or whatever zone my camera is set for)
      tzoLoc = timeZone(fileDateUTC, timeZonesFile)
      timeChange = (3600*tzoLoc) # previously had error capture on this. Maybe for general cases which I'm not longer covering
      fileDate = fileDateUTC + timeChange # date in local time photo was taken
    
      fileDateUTCstr = fileDateUTC.to_s[0..-6]

      filePrev = fn
      # Working out if files at the same time
      # puts "\nxx.. #{fileCount}. oneBack: #{oneBack}."
      # Determine dupCount, i.e., 0 if not in same second, otherwise the number of the sequence for the same time
      
      # Now the fileBaseName. Simple if not in the same second, otherwise an added sequence number
      oneBack = fileDate == fileDatePrev # true if previous file at the same time calculated in local time
      # puts "252.. oneBack: #{oneBack}. #{item}"
      if oneBack
        dupCount =+ 1
        fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  seqLetter[dupCount] + userCamCode(fn)            
      else # normal condition that this photo is at a different time than previous photo
        dupCount = 0 # resets dupCount after having a group of photos in the same second
        fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S")  + userCamCode(fn)
      end # if oneBack
      
      fileDatePrev = fileDate
      fileBaseNamePrev = fileBaseName
   
      # File renaming and/or moving happens here
      # puts "fn: #{fn}. imageFile: #{imageFile}. fileDateUTC: #{fileDateUTC}. tzoLoc:#{tzoLoc}"
      fileAnnotate(fn, fileEXIF, fileDateUTCstr, tzoLoc) # adds original file name, capture date and time zone to EXIF. Comments which I think show up as instructions in Aperture
      fnp = src + fileBaseName + File.extname(fn).downcase
      File.rename(fn,fnp)          
    end # 3. if File
  end # 2. Find  
end # renaming photo files in the downloads folder and writing in original time.

def addCoordinates(destPhoto, folderGPX, gpsPhotoPerl)
  # Remember writing a command line command, so telling perl, then which perl file, then the gpsphoto.pl script options
  # maxTimeDiff = 50000 # seconds, default 120, but I changed it 2011.07.26 to allow for pictures taken at night but GPS off. Distance still has to be reasonable, that is the GPS had to be at the same place in the morning as the night before as set by the variable below
  # Need to add a note to file with large time diff
  # This works, put in because having problems with file locations
  # perlOutput = `perl \"#{gpsPhotoPerl.shellescape}\" --dir #{destPhoto.shellescape} --gpsdir #{folderGPX.shellescape} --timeoffset 0 --maxtimediff 50000 2>&1`
  puts "285.. gpsPhotoPerl.shellescape: #{gpsPhotoPerl.shellescape}"
  perlOutput = `perl '/Users/gscar/Documents/Ruby/Photo\ handling/lib/gpsPhoto.pl' --dir '/Volumes/Knobby\ Aperture\ II/_Download\ folder/Latest\ Download/' --gpsdir '/Users/gscar/Dropbox/\ \ \ GPX\ daily\ logs/2013\ Download/' --timeoffset 0 --maxtimediff 50000`
      
  puts "\n273. perlOutput: \n#{perlOutput} \n\nEnd of perlOutput ================…273\n\n" # This didn't seem to be happening with 2>&1 appended? But w/o it, error not captured
  # perlOutput =~ /timediff\=([0-9]+)/
  # timediff = $1 # class string
  # # puts"\n 453 timediff: #{timediff}. timediff.class: #{timediff.class}. "
  # if timediff.to_i > 240
  #   timeDiffReport = ". Note that timediff is #{timediff} seconds. "
  #   # writing to the photo file about high timediff
  #   writeTimeDiff(imageFile,timediff)
  # else
  #   timeDiffReport = ""
  # end # timediff.to…
  return perlOutput
end

def addLocation(src)
  # read coords and add a hierarchy of choices for location information. Look at GPS Log Renaming for what works.
  Dir.foreach(src) do |item| 
    next if item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon ' # See notes in rename method
    fn = src + item
    if File.file?(fn) 
      puts "308.. No location information written  yet."
      fileEXIF = MiniExiftool.new(fn)
      # Special Instructions            : Lat 33.812123, Lon -118.383647 - Bearing: unknown - Altitude: 29m. Individual lat and long are in deg min sec
      gps = fileEXIF.specialinstructions.split(", ") # or some way of getting lat and lon. This is a good start. Look at input form needed
      timeNowWas = timeStamp(timeNowWas)
      puts "gps: #{gps}. gps.class: #{gps.class}"
      latIn = gps[0][4,11]
      longIn = gps[1][4,11]
      # Now have lat and long and now get some location names
    end
  end  
end

## The "program" #################
timeNowWas = timeStamp(Time.now) # this first use of timeStamp is different
puts "Fine naming and moving started………………………" # for trial runs  #{timeNowWas}
srcSD = srcSDfolder + sdFolder(sdFolderFile)

# Ask whether working with photo files from SD card or HD
fromWhere = whichLoc() # This is pulling in first Pashua window (1. ), SDorHD.rb which has been required
whichDrive = fromWhere["whichDrive"][0].chr # only using the first character
# puts "279.. whichDrive: #{whichDrive}"
# Set the return into a more friendly variable and set the src of the photos to be processed
whichOne = whichOne(whichDrive) # parsing result to get HD or SD
if whichOne=="SD" # otherwise it's HD, probably should be case to be cleaner coding
  # read in last filename copied from card previously
  begin
    file = File.new(lastPhotoReadTextFile, "r")
    lastPhotoFilename = file.gets # apparently grabbing a return. maybe not the best reading method.
    puts "\n303. lastPhotoFilename: #{lastPhotoFilename.chop}. Read from #{lastPhotoReadTextFile}. Value can be changed by user, so this may not be the final value."
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

puts "#{Time.now-timeNowWas}. #{Time.now}"
timeNowWas = Time.now

#  If working from SD card, copy or move files to " Drag Photos HERE Drag Photos HERE" folder, then will process from there.
copySD(src, srcHD, sdFolderFile, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) if whichOne == "SD"
#  Note that file creation date is the time of copying. May want to fix this. Maybe a mv is a copy and move which is sort of a recreation. 

# src = srcHD # switching since next part works from copied files on hard drive. 
timeNowWas = timeStamp(timeNowWas)
puts "\n336. Photos will now be moved and renamed.\n"

puts "#{(Time.now-timeNowWas).to_i} seconds. #{Time.now.strftime("%I:%M:%S %p")}" ; timeNowWas = Time.now

# puts "First will copy to the final destination where the renaming will be done and the original moved to an archive (already imported folder)"
#  Only copy jpg to destPhoto if there is not a corresponding raw, but keep all taken files. With Panasonic JPG comes before RW2
copyAndMove(srcHD,destPhoto,destOrig)

timeNowWas = timeStamp(timeNowWas)

timeNowWas = Time.now
# Rename the photo files with date and an ID for the camera or photographer
rename(destPhoto, timeZones)

timeNowWas = timeStamp(timeNowWas)

puts "\n345. Using perl script to add gps coordinates. Will take a while as all the files will be processed. #{Time.now}"

puts "#{(Time.now-timeNowWas).to_i} seconds. #{Time.now.strftime("%I:%M:%S %p")}" ; timeNowWas = Time.now

# Add GPS coordinates. Will add location later using some options depending on which country since different databases are relevant.
perlOutput = addCoordinates(destPhoto, folderGPX, gpsPhotoPerl)

# Parce perlOutput and add maxTimeDiff info to photo files

# Add location information
addLocation(destPhoto)

puts "#{(Time.now-timeNowWas).to_i} seconds. #{Time.now.strftime("%I:%M:%S %p")}" ; timeNowWas = Time.now