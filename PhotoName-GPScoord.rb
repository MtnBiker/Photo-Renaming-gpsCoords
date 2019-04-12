#!/usr/bin/env ruby
# Can't run from TextMate on iMac, must use iTerm
# Can be made to work with TS5 completely because GPS coordinates are batch added and TS5 photos missing coordinates have different time stamp than other cameras, so have to modify --timeoffset in Perl script by hand for batch of TS5 photos. Is still true since added options for travel and TS5?
#  Look at speeding up with https://github.com/tonytonyjan/exif for rename and annotate which is rather slow. 8 min. for 326 photos
# require 'rubygems' # # Needed by rbosa, mini_exiftool, and maybe by appscript. Not needed if correct path set somewhere.
system ('gem env') # for debugging problem with gem not loading https://stackoverflow.com/questions/53202164/textmate-chruby-and-ruby-gems
puts "\nGem.path: #{Gem.path}"
require 'fileutils'
include FileUtils
require 'find'
require 'yaml'
require "time"
require 'shellwords'
require 'irb' # binding.irb where error checking is desired
require 'mini_exiftool' # PATH in TM to $PATH:/usr/local/bin for exiftool to be seen (careful easy to mix mini_exiftool and exiftool issues)
# require 'exif' # added later. A partial implementation of ExifTool, but faster than mini_exiftool. Commented out since doesn't work with Panasonic Raw
# require 'geonames'
# require '/Library/Ruby/Gems/2.3.0/gems/addressable-2.5.2/lib/addressable/template.rb'
# require '/Library/Ruby/Gems/2.3.0/gems/addressable-2.5.2/lib/addressable/version.rb'
# load 'geonames.rb' # Note this is a file, not a gem. I guess the gem didn't work?
load '/Users/gscar/Documents/Ruby/Garmin Log renaming/geonames.rb' # above fails from command line. Even if move file there; currently it is an alias

require_relative 'lib/gpsYesPashua'
require_relative 'lib/LatestDownloadsFolderEmpty_Pashua'
require_relative 'lib/Photo_Naming_Pashua-SD2'
require_relative 'lib/Photo_Naming_Pashua–HD2'
require_relative 'lib/SDorHD'

thisScript = File.dirname(__FILE__) +"/" # needed because the Pashua script calling a file seemed to need the directory. 
lastPhotoReadTextFile = "/Volumes/LUMIX/DCIM/" # SD folder alternate since both this and one below occur 
sdCardAlt   = "/Volumes/NO NAME/"
sdCard      = "/Volumes/LUMIX/"
srcSDfolderAlt = sdCardAlt + "DCIM/" # SD folder alternate since both this and one below occur 
srcSDfolder = sdCard + "DCIM/"  # SD folder 

# Quit using this file and just get the folder name from the file name which will be stored on the card.
sdFolderFile = thisScript + "currentData/SDfolder.txt" # shouldn't need full path

# Appropriate temporary folders on laptop
# srcHD = "/Users/gscar/Pictures/_Photo Processing Folders/Download folder/" # for laptop use. NEED TO SET UP TRAVEL OPTION/ ?? Dec 2018 doesn't make sense anymore. Maybe it does for traveling with MBP
laptopLocation = "/Users/gscar/Pictures/_Photo Processing Folders/"
laptopDownloadsFolder = laptopLocation + "Download folder/"
laptopDestination     = laptopLocation + "Processed photos to be imported to Aperture/"
laptopDestOrig        = laptopLocation + "Originals to archive/"

# Folders on portable drive: Daguerre
downloadsFolders = "/Volumes/Daguerre/_Download folder/"
# downloadsFolders = "/Users/gscar/Pictures/_Download folder iMac/" # temp on iMac until Daguerre is back
srcHD     = downloadsFolders + " Drag Photos HERE/"  # Photos copied from camera, sent by others, etc.
destPhoto = downloadsFolders + "Latest Download/" #  These are relabeled and GPSed files.
destOrig  = downloadsFolders + "_imported-archive" # folder to move originals to if not done in. No slash because getting double slash with one
# destOrig  = "/Users/gscar/Documents/◊ Pre-trash/duplicates" # TEMP FOR REDOING

lastPhotoReadTextFile = thisScript + "currentData/lastPhotoRead.txt"
puts "52. lastPhotoReadTextFile: #{lastPhotoReadTextFile}. "
geoInfoMethod = "wikipedia" # for gpsPhoto to select georeferencing source. wikipedia—most general and osm—maybe better for cities
timeZonesFile = "/Users/gscar/Dropbox/scriptsEtc/Greg camera time zones.yml"
timeZones = YAML.load(File.read(timeZonesFile)) # read in that file now and get it over with
gpsPhotoPerl = thisScript + "lib/gpsPhoto.pl"
folderGPX = "/Users/gscar/Dropbox/ GPX daily logs/2019 Massaged/" # Could make it smarter, so it knows which year it is. Massaged contains gpx files from all locations whereas Downloads doesn't. This isn't used by perl script
puts "58. Must manually set folderGPX for GPX file folders. Particularly important at start of new year.\n "
geoNamesUser    = "MtnBiker" # This is login, user shows up as MtnBiker; but used to work with this. Good but may use it up. Ran out after about 300 photos per hour. This fixed it.
geoNamesUser2   = "geonamestwo" # second account when use up first. Or use for location information, i.e., splitting use in half. NOT IMPLEMENTED

def lineNum()
  caller_infos = caller.first.split(":")
  # Note caller_infos[0] is file name
  caller_infos[1]
end # line numbers of this file, useful for debugging and logging info to progress screen

def ignoreNonFiles(item) # invisible files that shouldn't be processed
  item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon '
  # This is true when it should not be processed i.e. next if ignoreNonFiles(item) == true
  # next if ignoreNonFiles(item) == true # how to use this
end

def gpsFilesUpToDate(folderGPX)
  # Find latest file, will have to be alphabetical order since creation date is date copied to drive.
  # Check date of file with current date, i.e. parse the file name. 
  # Compare and report.
  # Have to do after select location of files
end

def timeStamp(timeNowWas)  
  seconds = Time.now-timeNowWas
  minutes = seconds/60
  if minutes < 2
    report = "#{lineNum}. #{seconds.to_i} seconds"
  else
    report = "#{lineNum}. #{minutes.to_i} minutes"
  end   
  puts "-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -   #{report}. #{Time.now.strftime("%I:%M:%S %p")}   -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  "
  Time.now
end

def sdFolder(sdFolderFile)  
  begin
    file = File.new(sdFolderFile, "r")
    sdFolder = file.gets
    file.close
  # rescue Exception => err # Shouldn't rescue and Exception
  rescue StandardError => err # or can write "rescue => err" since Ruby assumes it's standard error
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
  puts "\n#{lineNum}. Copying photos from an SD card starting with #{lastPhotoFilename} or from another value manually entered"
  cardCount = 0
  cardCountCopied = 0
  doAgain = true # name isn't great, now means do it. A no doubt crude way to run back through the copy loop if we moved to another folder.
  # timesThrough = 1
  fileSDbasename = "" # got an error at puts fileSDbasename
  while doAgain==true # and timesThrough<=2 
    Dir.chdir(src) # needed for glob
    Dir.glob("P*") do |item| 
      cardCount += 1
      print(".") # crude activity bar. This doesn't happen
      # put cardCount # another try at activity bar
      # puts "#{lineNum}.. src/item: #{src}#{item}."
      fn = src + item
      fnp = srcHD + "/" + item # using srcHD as the put files here place, might cause problems later
      # get filename and make select later than already downloaded
      fileSDbasename = File.basename(item,".*")
      # puts "#{lineNum}. #{cardCount}. item: #{item}. fn: #{fn}"
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
        
        # This begin rescue end not needed since now getting folder name from file name
        # begin
        #   # Writing which folder we're now in
        #   # fileNow = File.open(thisScript + sdFolderFile, "w") # Was 2014.02.28 How could this have worked?
        #   fileNow = File.open(sdFolderFile, "w")
        #   fileNow.write(nextFolderName)
        # rescue IOError => e
        #   puts "Something went wrong. Could not write last photo read (#{nextFolderName}) to #{sdFolderFile}"
        # ensure
        #     fileNow.close unless fileNow == nil
        # end # begin writing sdFolderFile
        # puts "\n#{nextFolderName} File.exist?(nextFolderName): #{File.exist?(nextFolderName)}" 
        src = srcSDfolder + nextFolderName + "/"
        if File.exist?(src)
          doAgain = true
        else
          doAgain = false
        end     
        puts "#{lineNum}. Now copying from #{src} as we finished copying from the previous folder.\n"
    end
  end # if doAgain…
  # Writing which file on the card we ended on
  begin
      fileNow = File.open(lastPhotoReadTextFile, "w") # must use explicit path, otherwise will use wherever we are are on the SD card
      fileNow.puts fileSDbasename
      fileNow.close
      puts "\n#{lineNum}. The last file processed. fileSDbasename, #{fileSDbasename}, written to  #{fileSDbasename}."
  rescue IOError => e
    puts "Something went wrong. Could not write last photo read (#{fileSDbasename}) to #{fileNow}"
  end # begin
    puts "\n#{lineNum}. Of the #{cardCount} photos on the SD card, #{cardCountCopied} were copied to #{src}" #last item was src, doesn't make sense
end # copySD

def uniqueFileName(filename)
  # https://www.ruby-forum.com/topic/191831#836607
  count = 0
  unique_name = filename
  while File.exists?(unique_name)
    count += 1
    unique_name = "#{File.join(File.dirname(filename),File.basename(filename, ".*"))}-#{count}#{File.extname(filename)}"
  end
  unique_name
end

def copyAndMove(srcHD,destPhoto,destOrig)
  puts "\n#{lineNum}. Copy photos from #{srcHD}\n      to #{destPhoto} where the renaming will be done, \n      and the originals moved to an archive folder (#{destOrig})\n Running dots are progress bar" 
  # Only copy jpg to destPhoto if there is not a corresponding raw, but keep all taken files. With Panasonic JPG comes before RW2
  # Guess this method is slow because files are being copied
  # THIS METHOD WILL NOT WORK IF THE RAW FILE FORMAT ALPHABETICALLY COMES BEFORE JPG. SHOULD MAKE THIS MORE ROBUST
  photoFinalCount = 0
  delCount = 1
  itemPrev = "" # need something for first time through
  fnp = "" # when looped back got error "undefined local variable or method ‘fnp’ for main:Object", so needs to be set here to remember it. Yes, this works, without this statement get an error
  # puts "#{lineNum}. Files in #{srcHD}: #{Dir.entries(srcHD).sort}" # list of files to be processed
  Dir.entries(srcHD).sort.each do |item| # This construct goes through each in order. Sometimes the files are not in order with Dir.foreach or Dir.entries without sort
    # Item is the file name
    # puts "\n#{lineNum}.. photoFinalCount: #{photoFinalCount + 1}. item: #{item}." # kind of a progress bar
    next if item == '.' or item == '..' or item == '.DS_Store'
    # next if ignoreNonFiles(item) == true
    # fileExt = File.extname(item)
    if File.basename(itemPrev, ".*") == File.basename(item,".*") && photoFinalCount != 0
     #  The following shouldn't be necessary, but is a check in case another kind of raw or who know what else. Only the FileUtils.rm(itemPrev) should be needed
     itemPrevExtName = File.extname(itemPrev) # since reusing below
     # TODO Add an option to keep jpgs. May want to see how camera is converting them. May end up having problem with labeling as then would have two photos taken at the same time and the Raw will always be a .b
      if itemPrevExtName == ".JPG" or itemPrevExtName == ".jpg" # added lower case for iPhone to sort HEIC
        FileUtils.rm(fnp) # Removing the jpg file from LatestDownload which is "duplicate" of a RAW that we're now considering. Can comment this out to keep both
        puts "#{lineNum}.. #{delCount}. fnp: #{itemPrev} will not be transferred because it's a jpg duplicate of a RAW version." # Is this slow? Turned off to try. Not sure.
        delCount += 1
        photoFinalCount -= 1
      elsif
        if itemPrevExtName == ".HEIC"
          FileUtils.rm(destPhoto + itemPrev)
        end
        puts "#{lineNum}. Something very wrong here with trying to remove JPGs when there is a corresponding .RW2 or .HEIC. itemPrev: #{itemPrev}. item: #{item}."
      end # File.extname  
    end   # File.basename
    fn  = srcHD     + item # sourced from Drag Photos Here
    fnp = destPhoto + item # new file in Latest Download
    # puts "#{lineNum}. Copy from fn: #{fn}"  # debugging
    fnf = destOrig  + item # to already imported
    # puts "#{lineNum}. to fnp: #{fnp}" # debugging
    FileUtils.copy(fn, fnp) # making a copy in the Latest Downloads folder for further action
    # puts "#{lineNum}.#{photoFinalCount}. #{fn} copied to #{fnp}" # dubugging
    if File.exists?(fnf)  # moving the original to _imported-archive, but not writing over existing files
      fnf = uniqueFileName(fnf)
      FileUtils.move(fn, fnf)
      puts "#{lineNum}. A file already existed with this name so it was changed to fnf: #{fnf}"
    else # no copies, so move
      # puts "#{lineNum}.#{photoFinalCount}. #{fn} moved to #{fnf}" # dubugging
      FileUtils.move(fn, fnf)
    end # File.exists?
    # "#{lineNum}.. #{photoFinalCount + delCount} #{fn}" # More for debugging, but maybe OK as progress in this slow process
    itemPrev = item
    photoFinalCount += 1
    print "." # Trying to get a progress bar
  end # Dir.entries
  # puts "\#{lineNum}. #{photoFinalCount} photos have been moved and are ready for renaming and gpsing. #{delCount-1} duplicate jpg were not
  if delCount > 1
    comment = ". #{delCount-1} duplicate jpg were not moved."
  else
    comment = ""
  end
  puts "\n#{lineNum}. #{photoFinalCount} photos have been moved and are ready for renaming and adding GPS coordinates and locations#{comment}"
end # copyAndMove: copy to the final destination where the renaming will be done and the original moved to an archive (_imported-archive folder)

def unmountCard(card)
  puts "#{lineNum}. card: #{card}" 
  card = card[-8, 7]
  puts "#{lineNum}. card: #{card}" 
  card  = "\"" + card + "\""
  disk =  `diskutil list |grep #{card} 2>&1`
  puts "\n#{lineNum}. disk: #{disk}"
  # Getting confused because grabbing the last 7 twice. And naming sucks (mjy fault)
  driveID = disk[-8, 7] # not sure this syntax is precise, but it's working.
  puts "#{lineNum} Unmount #{card}. May have to code this better. See if card name is already a variable. This is hard coded for a specific length of card name"
  puts "#{lineNum}. driveID: #{driveID}. card: #{card}" 
  cmd =  "diskutil unmount #{driveID} 2>&1"
  puts "cmd: #{cmd}"
  unmountResult = `diskutil unmount #{driveID} 2>&1`
  puts "\n#{lineNum}. SD card, #{unmountResult}, unmounted."  
end #unm

def userCamCode(fn)
  fileEXIF = MiniExiftool.new(fn)
  ## not very well thought out and the order of the tests matters
  case fileEXIF.model
  when "DMC-GX8"
    userCamCode = ".gs.P" # gs for photographer. P for *P*anasonic Lumix
  when "iPhone X"
    userCamCode = ".i" # gs for photographer. i for iPhone
  # when "DMC-GX7"
  #   userCamCode = ".gs.P" # gs for photographer. P for *P*anasonic Lumix
  when "DMC-TS5"
    userCamCode = ".gs.W" # gs for photographer. W for *w*aterproof Panasonic Lumix DMC-TS5
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

def fileAnnotate(fn, fileEXIF, fileDateTimeOriginalstr, tzoLoc)  # writing original filename and dateTimeOrig to the photo file.
  # Called from rename
  # writing original filename and dateTimeOrig to the photo file.
  # SEEMS SLOPPY THAT I'M OPENING THE FILE ELSEWHERE AND SAVING IT HERE
  if fileEXIF.source.to_s.length < 2 # if exists then don't write. If avoid rewriting, then can eliminate this test. Was a test on comment, but not sure what that was and it wasn't working.
    # puts "#{lineNum}. tzoLoc #{tzoLoc}"
    if tzoLoc.to_i < 0
      tzoLocPrint = tzoLoc
    else
      tzoLocPrint = "+" + tzoLoc.to_s
    end
    fileEXIF.instructions = "#{fileDateTimeOriginalstr} #{tzoLocPrint}" # Time zone of photo is GMT #{tzoLoc} unless TS5?" or travel
    # fileEXIF.comment = "Capture date: #{fileDateTimeOriginalstr} UTC. Time zone of photo is GMT #{tzoLoc}. Comment field" # Doesn't show up in Aperture
    # fileEXIF.source = fileEXIF.title = "#{File.basename(fn)} original filename" # Source OK, but Title seemed a bit better
    fileEXIF.source = "#{File.basename(fn)}"
    fileEXIF.TimeZoneOffset = tzoLoc # Time Zone Offset, (1 or 2 values: 1. The time zone offset of DateTimeOriginal from GMT in hours, 2. If present, the time zone offset of ModifyDate)
    # Am I misusing this? I may using it as the TimeZone for photos taken GMT 0 TODO
    # OffsetTimeOriginal	(time zone for DateTimeOriginal) which may or may not be the time zone the photo was taken in TODO 
    
    # Wiping out bad GPS data on TS5. Maybe should test for TS5 to save checking all other files
    if !fileEXIF.GPSDateTime  # i.e. == "false" # condition if bad data for TS5. Note is nil for GX7. Not changing because can use as flag
      # puts "#{lineNum}. #{File.basename(fn)} has bad GPS data  (GPSDateTime is false), and will be blanked out\n"
      fileEXIF.gps_latitude = fileEXIF.gps_longitude = fileEXIF.gps_altitude = ""
    end    
    fileEXIF.save
  end
end # fileAnnotate. writing original filename and dateTimeOrig to the photo file and cleaning up TS5 photos with bad (no) GPS data.

# With the fileDateTimeOriginal for the photo, find the time zone based on the log.
# The log is in numerical order and used as index here. The log is a YAML file
def timeZone(fileDateTimeOriginal, timeZones)
  # theTimeAhead = "2050-01-01T00:00:00Z"
  # puts "276. timeZones: #{timeZones}. "
  # timeZones = YAML.load(File.read(timeZonesFile)) # should we do this once somewhere else? Let's try that in this new version
  i = timeZones.keys.max # e.g. 505
  j = timeZones.keys.min # e.g. 488
  while i > j # make sure I really get to the end 
    theTime = timeZones[i]["timeGMT"]
    # puts "\nA. i: #{i}. theTime: #{theTime}" # i: 502. theTime: 2011-06-29T01-00-00Z
    theTime = Time.parse(theTime) # class: time Wed Jun 29 00:00:00 -0700 2011
    # puts "\n#{lineNum}.. #{i}. fileDateTimeOriginal: #{fileDateTimeOriginal}. theTime: #{theTime}. fileDateTimeOriginal.class: #{theTime.class}. fileDateTimeOriginal.class: #{theTime.class}"
    # puts "Note that these dates are supposed to be UTC, but are getting my local time zone attached."
    if fileDateTimeOriginal > theTime
      theTimeZone = timeZones[i]["zone"]
      # puts "C. #{i}. fileDateTimeOriginal: #{fileDateTimeOriginal} fileDateTimeOriginal.class: #{fileDateTimeOriginal.class}. theTimeZone: #{theTimeZone}."
      return theTimeZone
    else
      i= (i.to_i-1).to_s
    end
  end # loop
  # puts "D. #{i}. fileDateTimeOriginal: #{fileDateTimeOriginal} fileDateTimeOriginal.class: #{fileDateTimeOriginal.class}. theTimeZone: #{theTimeZone}. "
  return theTimeZone
end # timeZone

def rename(src, timeZonesFile, timeNowWas)
  # src is destPhoto folder
  # timeZonesFile is my log of which time zones I was in when
  # timeNowWas used for timing various parts of the script. 
  # Until 2017, this assumed camera on UTC, but doesn't work well for cameras with a GPS or set to local time
  # So have to ascertain what time zone the camera is set to by other means in this script, none of them foolproof
  # 60 minutes for ~1000 photos to rename
  fileDatePrev = ""
  dupCount = 0
  count    = 0
  tzoLoc = ""
  seqLetter = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z aa bb cc) # seems like this should be an array, not a list
  Dir.foreach(src) do |item| # for each photo file
    next if ignoreNonFiles(item) == true # skipping file when true, i.e., not a file
    # puts "#{lineNum}. #{item} will be renamed. " # #{timeNowWas = timeStamp(timeNowWas)}
    fn = src + item # long file name
    fileEXIF = MiniExiftool.new(fn) # used several times
    # fileEXIF = Exif::Data.new(fn) # see if can just make this change, probably break something. 2017.01.13 doesn't work with Raw, but developer is working it.
    camModel = fileEXIF.model
    # puts "\n#{lineNum}. #{fileCount}. fn: #{fn}"
    # puts "#{lineNum}.. File.file?(fn): #{File.file?(fn)}. fn: #{fn}"
    if File.file?(fn)
      # Determine the time and time zone where the photo was taken
      # puts "315.. fn: #{fn}. File.ftype(fn): #{File.ftype(fn)}." #  #{timeNowWas = timeStamp(timeNowWas)}
      fileDateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
      if fileDateTimeOriginal == nil 
        # TODO This probably could be cleaned up, but then normally not used, movie files don't have this field
        fileDateTimeOriginal = fileEXIF.DateCreated  # PNG don't have dateTimeOriginal
        camModel ="MISC" # Dummy value for test below
        fileDateTimeOriginal == nil ? fileDateTimeOriginal = fileEXIF.CreationDate : "" # now fixing .mov files
        fileDateTimeOriginal == nil ? fileDateTimeOriginal = fileEXIF.MediaCreateDate : "" # now fixing .mp4 files. Has other dates, but at least for iPhone mp4s the gps info exists
      end # if fileDateTimeOriginal == nil
      panasonicLocation = fileEXIF.location # Defined by Panasonic if on trip (and also may exist for photos exported from other apps such as Photos). If defined then time stamp is that local time
      # puts "#{lineNum}. panasonicLocation: #{panasonicLocation}"
      tzoLoc = timeZone(fileDateTimeOriginal, timeZonesFile) # the time zone the picture was taken in, doesn't say anything about what times are recorded in the photo's EXIF. I'm doing this slightly wrong, because it's using the photo's recorded date which could be either GMT or local time. But only wrong if the photo was taken too close to the time when camera changed time zones
      puts count == 1 ? "#{lineNum}. panasonicLocation: #{panasonicLocation}. tzoLoc: #{tzoLoc} Time zone photo was taken in from Greg camera time zones.yml" : ""# Just to show one value, otherwise without if prints for each file
      # Also determine Time Zone TODO and write to file OffsetTimeOriginal	(time zone for DateTimeOriginal). Either GMT or use tzoLoc if recorded in local time as determined below
      # puts "#{lineNum}.. camModel: #{camModel}. #{tzoLoc} is the time zone where photo was taken. Script assumes GX8 on local time "
      # Could set timeChange = 0 here and remove from below except of course where it is set to something else
      timeChange = 0 # setting it outside the loops below and get reset each time through. But can get changed
      if camModel ==  "MISC" # MISC is for photos without fileDateTimeOriginal, e.g., movies
        # timeChange = 0
        fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
      elsif camModel.include?("DMC-GX7") and panasonicLocation.length > 0 or camModel == "DMC-TS5" or camModel == "DMC-GX8" or  # DateTimeOriginal is in local time. Look at https://sno.phy.queensu.ca/~phil/exiftool/TagNames/Panasonic.html for other Tags that could be used
        # Above first checking that is a Panasonic Lumix GX7 using travel, otherwise will error on second test which checks if using travel, 
        ### first criteria won't work for files exported from another app using GX7
        # timeChange = 0
        fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
#       puts "#{lineNum}: camModel: #{camModel}. tzoLoc: #{tzoLoc}. timeChange.class: #{timeChange.class} timeChange: #{timeChange.to_i}"
      elsif camModel == "iPhone X"  # DateTimeOriginal is in local time
        # timeChange = 0
        fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
      else
        timeChange = (3600*tzoLoc) # previously had error capture on this. Maybe for general cases which I'm not longer covering
        fileEXIF.OffsetTimeOriginal = "GMT"
      end # if camModel
      # puts "#{lineNum}.. timeChange: #{timeChange}"

      fileDate = fileDateTimeOriginal + timeChange.to_i # date in local time photo was taken. No idea why have to change this to i, but was nil class even though zero  
      fileDateTimeOriginalstr = fileDateTimeOriginal.to_s[0..-6]

      # filePrev = fn
      # Working out if files at the same time
      # puts "\nxx.. #{fileCount}. oneBack: #{oneBack}."
      # Determine dupCount, i.e., 0 if not in same second, otherwise the number of the sequence for the same time
      # puts "#{lineNum}.. #{timeStamp(timeNowWas)}"
      # Now the fileBaseName. Simple if not in the same second, otherwise an added sequence number
      oneBack = fileDate == fileDatePrev # true if previous file at the same time calculated in local time
      # puts "#{lineNum}.. oneBack: #{oneBack}. #{item}"
      if oneBack
        dupCount =+ 1
        fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  seqLetter[dupCount] + userCamCode(fn)            
      else # normal condition that this photo is at a different time than previous photo
        dupCount = 0 # resets dupCount after having a group of photos in the same second
        fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S")  + userCamCode(fn)
      end # if oneBack
      fileDatePrev = fileDate
      # fileBaseNamePrev = fileBaseName
   
      # File renaming and/or moving happens here
      # puts "#{lineNum}. #{count+1}. dateTimeOriginal: #{fileDateTimeOriginal}. item: #{item}. camModel: #{camModel}" # . #{timeNowWas = timeStamp(timeNowWas)} # took 1 sec per file
      fileAnnotate(fn, fileEXIF, fileDateTimeOriginalstr, tzoLoc) # adds original file name, capture date and time zone to EXIF. Comments which I think show up as instructions in Aperture. Also wiping out bad GPS data on TS5
      fnp = src + fileBaseName + File.extname(fn).downcase
      File.rename(fn,fnp)   
      count += 1
      # print " #{count}" Trying for  progress indicator
      # puts "#{lineNum}.#{count} #{timeNowWas = timeStamp(timeNowWas)}. #{fileBaseName}" # temp to see how long taking. 1 to 4 seconds on MBP accessing photos on attached portable drive
    end # 3. if File
    # puts "#{lineNum}. Got to here. tzoLoc: #{tzoLoc}"
    
  end # 2. Find
  # return tzoLoc # used by ?
  # puts "#{lineNum}. Got to here. tzoLoc: #{tzoLoc}" # tzoLoc doesn't exist here
  return tzoLoc # the time zone the picture was taken in,
end # renaming photo files in the downloads folder and writing in original time.

def addCoordinates(destPhoto, folderGPX, gpsPhotoPerl, loadingToLaptop, tzoLoc)
  # Remember writing a command line command, so telling perl, then which perl file, then the gpsphoto.pl script options
  # --timeoffset seconds     Camera time + seconds = GMT. No default.  
  # maxTimeDiff = 50000 # seconds, default 120, but I changed it 2011.07.26 to allow for pictures taken at night but GPS off. Distance still has to be reasonable, that is the GPS had to be at the same place in the morning as the night before as set by the variable below
  # This works, put in because having problems with file locations
  # perlOutput = `perl \"#{gpsPhotoPerl.shellescape}\" --dir #{destPhoto.shellescape} --gpsdir #{folderGPX.shellescape} --timeoffset 0 --maxtimediff 50000 2>&1`

# Assuming all the photos are from the same camera, get info on one and use that information. destPhoto is where they are. Can I get the third file in the folder (to avoid)
# GX7 is UST
# TS5. Need to determine time zone so can determine offset. 
  camModel = ""
  timeOffset = 0
  Dir.foreach(destPhoto) do |item|
    # This is only run once, so efficiency doesn't matter
    count = 0
    next if ignoreNonFiles(item)  # skipping file when true == true
    fn = destPhoto + item
    fileEXIF = MiniExiftool.new(fn) # used several times
    camModel = fileEXIF.model
    panasonicLocation = fileEXIF.location
    # timeOffset = 0 # could leave this in and remove the else     
    if File.file?(fn)
      if camModel  == "DMC-TS5"
        # Offset sign is same as GMT offset, eg, we are -8, but need to increase the time to match UST, therefore negative
        timeOffset = - fileEXIF.dateTimeOriginal.utc_offset # Time zone is set in camera, i.e. local time in this case
        # What does utc_offset do for the above. dateTimeOriginal is just a time, e.g., 2018:12:31 21:38:32, which is the time the camera thinks it is. Camera doesn't know about zone. Camera may, but from dateTimeOriginal, can't tell the time zone.
        puts "#{lineNum}. timeOffset: #{timeOffset} for DMC-TS5 photos stamped in local time."
      elsif camModel == "DMC-GX8"# Assumes GX8 always on local time. Made if's a bit more complex, but keeping logic simpler
        timeOffset = tzoLoc * 3600
        puts "#{lineNum}. timeOffset: #{timeOffset} with GX-8 photos stamped in local time."
      elsif camModel.include?("DMC") and panasonicLocation.length > 0 # Panasonic in Travel Mode, but also some photos exported from Photos. 
        timeOffset = tzoLoc * 3600
        puts "#{lineNum}. timeOffset: #{timeOffset} sec (#{tzoLoc} hours) with photos stamped in local time."
      else # GX7 time is UTC
        timeOffset = 0 # camelCase, but perl variable is lowercase
        puts "#{lineNum}. timeOffset: #{timeOffset} sec (#{tzoLoc} hours) with photos stamped in GMT"
      end # if camModel
      
      fileEXIF.save 
      count += 1
    end # if File.file
    break if count == 1 # once have a real photo file, can get out of this. Only check htis once
  end # Dir.foreach
  puts "#{lineNum}. timeOffset: #{timeOffset}. camModel: #{camModel}. All photos must be same camera and time zone or photos may be mislabeled and geo-located."
   
  puts "\n#{lineNum}. Finding all gps points from all the gpx files using gpsPhoto.pl. This may take a while. \n"
  # Since have to manually craft the perl call, need one for with Daguerre and one for on laptop
  # Daguerre version. /Volumes/Daguerre/_Download folder/Latest Download/
    if loadingToLaptop 
      # perlOutput = `perl '/Users/gscar/Documents/Ruby/Photo\ handling/lib/gpsPhoto.pl' --dir '/Users/gscar/Pictures/_Photo Processing Folders/Processed\ photos\ to\ be\ imported\ to\ Aperture/' --gpsdir '/Users/gscar/Dropbox/\ GPX\ daily\ logs/2017\ Massaged/' --timeoffset #{timeOffset} --maxtimediff 50000` # saved in case something goes wrong. This works
      perlOutput = `perl '#{gpsPhotoPerl}' --dir '#{destPhoto}' --gpsdir '#{folderGPX}' --timeoffset #{timeOffset} --maxtimediff 50000`
    else # default location on Daguerre or Knobby Aperture Two
      # perlOutput = `perl '/Users/gscar/Documents/Ruby/Photo\ handling/lib/gpsPhoto.pl' --dir '/Volumes/Knobby Aperture Two/_Download\ folder/Latest\ Download/' --gpsdir '/Users/gscar/Dropbox/\ GPX\ daily\ logs/2017\ Massaged/' --timeoffset #{timeOffset} --maxtimediff 50000` # this works, saving in case the following doesn't
      perlOutput = `perl '#{gpsPhotoPerl}' --dir '#{destPhoto}' --gpsdir '#{folderGPX}' --timeoffset #{timeOffset} --maxtimediff 50000`
      # Double quotes needed for variables to be evalated
      # perlOutput = "`perl \'#{gpsPhotoPerl.shellescape}\' --dir \'#{destPhoto.shellescape}\' --gpsdir \'#{folderGPX.shellescape}\' --timeoffset #{timeOffset} --maxtimediff 50000`" #  2>&1
      # perlOutput = "`perl '/Users/gscar/Documents/Ruby/Photo\ handling/lib/gpsPhoto.pl' --dir '/Volumes/Knobby Aperture Two/_Download\ folder/Latest\ Download/' --gpsdir '/Users/gscar/Dropbox/\ GPX\ daily\ logs/2017\ Massaged/' --timeoffset #{timeOffset} --maxtimediff 50000 2>&1` " #  2>&1 is needed to capture output, but not to run
      
      puts "#{lineNum}. perlOutput: #{perlOutput}"
    end
      
  # puts "\n374.. perlOutput: \n#{perlOutput} \n\nEnd of perlOutput ================… end 374\n\n" # This didn't seem to be happening with 2>&1 appended? But w/o it, error not captured
  # perlOutput =~ /timediff\=([0-9]+)/
  # timediff = $1 # class string
  # # puts"\n #{lineNum} timediff: #{timediff}. timediff.class: #{timediff.class}. "
  # if timediff.to_i > 240
  #   timeDiffReport = ". Note that timediff is #{timediff} seconds. "
  #   # writing to the photo file about high timediff
  #   writeTimeDiff(imageFile,timediff)
  # else
  #   timeDiffReport = ""
  # end # timediff.to…
  return perlOutput
end # addCoordinates

def addLocation(src, geoNamesUser)
  # read coords and add a hierarchy of choices for location information. Look at GPS Log Renaming for what works.
    countTotal = 0 
    countLoc = 0
    Dir.foreach(src) do |item| 
      next if ignoreNonFiles(item) == true # skipping file when true
      fn = src + item
      if File.file?(fn) 
        countTotal += 1
        puts "\n#{lineNum}. #{countTotal}. #{item}. Adding location information using geonames based on coordinates. " # amounts to a progress bar, even if a bit verbose #{timeStamp(timeNowWas)}
        fileEXIF = MiniExiftool.new(fn)
        # Get lat and lon from photo file. What is this fileEXIF.specialinstructions. What about 
        puts "#{lineNum}. No gps information for #{item}. #{fileEXIF.title}. fileEXIF.specialinstructions: #{fileEXIF.specialinstructions}" if fileEXIF.specialinstructions == nil
        next if fileEXIF.specialinstructions == nil # can I combine this step and the one above into one step or if statement? 
        # puts "#{lineNum}. fileEXIF.specialinstructions: #{fileEXIF.specialinstructions}"
        gps = fileEXIF.specialinstructions.split(", ") # or some way of getting lat and lon. This is a good start. Look at input form needed
        lat = gps[0][4,11] # Capture long numbers like -123.123456, but short ones aren't that long, but nothing is there
        lon = gps[1][4,11].split(" ")[0] # needs to 11 long to capture when -xxx.xxxxxx, but then can capture the - when it's xx.xxxxxx. Then grab whats between the first two spaces. Still need the 4,11 because there seems to be a space at the beginning if leave out [4,11]

        # puts " #{lineNum}. #{lat} #{lon} for #{fn}" # put here because of fail with TS5 file with erroneous lat lon
        # puts " #{lineNum}. #{lat.to_i} #{lon.to_i} for #{fn}" # put here because of fail with TS5 file with erroneous lat lon        
        # Quick and dirty to block erroneous TS5 results, but need to fix coordinates earlier.
        if lat.to_i > 180 
          puts "#{lineNum}. #{fn} is a TS5 photo with erroneous GPS data, but the script needs to be fixed to add data"
        end
        next if lat.to_i > 180 # takes care of erroneous GPS coords in TS5 photos, but need to fix
        countLoc += 1 # gives an error here or at the end.
        # puts "#{lineNum}..#{countTotal}. Use geonames to determine city, state, country, and location for #{item}"
        api = GeoNames.new(username: geoNamesUser)
        # puts "#{lineNum}.. geoNamesUser: #{geoNamesUser}. api: #{api}"

        # Determine country 
        begin
          # doesn't work for Istanbul, works for Croatia, Canada
          countryCodeGeo = api.country_code(lat: lat, lng: lon) # doesn't work in Turkey
          # puts "#{lineNum}.. countryCodeGeo: #{countryCodeGeo}"
          countryCode  = countryCodeGeo['countryCode']
          puts "#{lineNum}.. countryCode #{countryCode}."
        rescue
          # begin
   #          # Commented out because of errors with "invalid user"
            countryCodeGeo = api.find_nearby_place_name(lat: lat, lng: lon).first # works for Turkey
   #          puts "#{lineNum}.. countryCodeGeo:\n#{countryCodeGeo}"
   #          countryCode  = countryCodeGeo['countryCode']
   #        rescue SocketError # SocketError: getaddrinfo: nodename nor servname provided, or not known. NOT SURE WHAT THE FAILURE IS HERE. WILL SEE IF IT HAPPENS AGAIN
   #          puts " #{lineNum}. Failing for api.find_nearby_place_name(lat: lat, lng: lon).first #{lat} #{lon} \nfor #{fn}\n"
   #          $stderr.print  $! # Thomas p. 108
   #        end
        end
       
      # puts "#{lineNum}.. countryCode:  #{countryCode}"
      # puts "#{lineNum}. NEED TO UNCOMMENT THIS AFTER INDONESIA ##############################################"
      country = countryCodeGeo['countryName'] # works with both country_code  and find_nearby_place_name above
      # puts "#{lineNum}.. country:      #{country}"
      #
      # Determine city, state, location
      if countryCode == "US"
        begin # state
          postalCodes = api.find_nearby_postal_codes(lat: lat, lng: lon, maxRows: 1) # this comes up blank for some locations in the US eg P1230119, so did find_nearest_address 
          state = postalCodes.first['adminName1']
          # puts "#{lineNum}.. api.find_nearby_postal_codes worked"
        rescue 
          state = api.country_subdivision(lat: lat, lng: lon, maxRows: 1)['adminName1']
          # puts "#{lineNum}. api.find_nearby_postal_codes failed, so used  api.country_subdivision"
        end # if country code
        # puts "#{lineNum}.. state:        #{state}"
        
        begin  # city, location
          neigh = api.neighbourhood(lat: lat, lng: lon) # errors outside the US and at other time
          city =  neigh['city']
          # puts "#{lineNum}.. city:         #{city}"
          location = neigh['name']
          # puts "386.. location:     #{location}"
        rescue # could use api.find_nearby_postal_codes for some of this
          # puts "344.  api.neighbourhood failed for #{lat} #{lon}"
          
          begin # within a rescue
            city = postalCodes.first['placeName'] # breaking for some points, but is it better than replacement? If so add another rescue
            # puts "#{lineNum}.. city (rescue): #{city}"
            findNearbyPlaceName = api.find_nearby_place_name(lat: lat, lng: lon)
            location = findNearbyPlaceName.first['toponymName']
            # puts "#{lineNum}.. location (rescue): #{location}"      
          rescue # probably end up here for a remote place, so wikipedia may be the best
            # puts "#{lineNum}.. find_nearby_postal_codes failed for city, so use Wikipedia to find a location"
            city = ""
            distance = api.find_nearby_wikipedia(lat: lat, lng: lon, maxRows: 1)['geonames'].first['distance']
            location = api.find_nearby_wikipedia(lat: lat, lng: lon, maxRows: 1)['geonames'].first['title']
            puts "#{lineNum}.. location:     #{location}. distance: #{distance}" # may need to screen as for outside US
          end # of within a rescue
  
        end # begin rescue outer
        
      else # outside US. Doesn't work in Indonesia
        
        # Uncomment below for Indonesia. Could probably generalize this for other countries. But it requires downloading the file to pgAdmin and building a database.
        # locationIN  = indoLocation(lat,lon)
 #        countryCode  = locationIN[0]
 #        city         = locationIN[1]
 #        location     = locationIN[2]
 #        if countryCode == "ID"
 #          country = "Indonesia"
 #        else
 #          country = ""
 #        end
                 
        # off for Indonesia and Ethiopia, just skip if         
        begin
          findNearbyPostalCodes = api.find_nearby_postal_codes(lat: lat, lng: lon, maxRows: 1).first
          state = findNearbyPostalCodes['adminName1']
          puts "#{lineNum}.. state (outside US): #{state}"
          city = findNearbyPostalCodes['placeName'] # close to city, but misses Dubrovnik and Zagreb
          # Below was normal I think, but turned off to try to get Canada to work
          city = api.find_nearby_place_name(lat: lat, lng: lon, maxRows: 1).first['toponymName'] # name or adminName1 could work too
          puts "#{lineNum}.. city (outside US):  #{city}"
        rescue
          puts "#{lineNum}. findNearbyPostalCodes failed, probably in a foreign country"
        end
        
        # puts city =  api.find_nearby_wikipedia(lat: lat, lng: lon)["geonames"].first["title"] # the third item is a city, maybe could regex wikipedia, but doubt it's consistent enough to work
        puts "#{lineNum}.. Four lines below commented out for Canada"
        
        begin # put this in with failure anotating Ethiopia photos
          location = api.find_nearby_wikipedia(lat: lat, lng: lon, maxRows: 1)['geonames'].first['title']
          distance = api.find_nearby_wikipedia(lat: lat, lng: lon, maxRows: 1)['geonames'].first['distance'].to_f
          puts "#{lineNum}. location:     #{location}. distance: #{distance}. If distance > 0.3km location not used"
          location = "" if distance < 0.3
        rescue
          puts "#{lineNum}. #{item} find api.find_nearby_wikipedia failed. Maybe a foreign country? "
          location = "" # added this to help prevent failure on test below. May not be necessary
        end
        
        
      end # if countryCode
      location = "" if city == location # cases where they where the same (Myers Flat, Callahan and Etna). Could try to find a location with some other find, maybe Wikipedia, but would want a distance check
      # puts "#{lineNum}.. Use MiniExiftool to write location info to photo files\n" # Have already set fileEXIF
      fileEXIF.CountryCode = countryCode  # Aperture: IPTC: Country-PrimaryLocationCode
      fileEXIF.country = country  # Aperture: IPTC: Country-Primary Location Name
      fileEXIF.state = state # Aperture: IPTC: Province-State (XMP: Stqte)
      fileEXIF.city = city # Aperture: IPTC: City
      fileEXIF.location = location # Aperture: IPTC: Sub-location
      fileEXIF.save
      # Now have lat and long and now get some location names
    end    
  end 
  puts "\n#{lineNum}. Location information found for #{countLoc} of #{countTotal} photos processed" 
end # addLocation

def indoLocation(lat,lon) # Could modiby for other countries. Uses file loaded into PGadmin
  conn = PG.connect( dbname: 'Indonesia' )
  #  lon/lat is the order for ST_GeomFromText
  indo  = conn.exec("SELECT * FROM indonesia ORDER BY ST_Distance(ST_GeomFromText('POINT(#{lon} #{lat})', 4326), geom) ASC LIMIT 1")
  country = indo.getvalue(0,8)
  name    = indo.getvalue(0,1)
  altNames= indo.getvalue(0,3)
  # puts "\#{lineNum}. Indonesia country: #{country}"
  # puts "#{lineNum}. Indonesia name: #{name}"
  # puts "#{lineNum}. Indonesia alt names: #{altNames}"
  result = [country, name, altNames]
  # puts "\#{lineNum} result #{result}"
end

def writeTimeDiff(perlOutput)
  perlOutput.each_line do |line|
    if line =~ /timediff=/
      fn = $`.split(",")[0]
      timeDiff = $'.split(" ")[0]
      # puts "\n515.. #{fn} timeDiff: #{timeDiff}"
      fileEXIF = MiniExiftool.new(fn)
      fileEXIF.usageterms = "#{sprintf '%.0f', timeDiff} seconds from nearest GPS point"
      fileEXIF.save
    end
  end
end #  Write timeDiff to the photo files

## The "PROGRAM" #################
timeNowWas = timeStamp(Time.now) # Initializing. Later calls are different
# timeNowWas = timeStamp(timeNowWas)
puts "Are the gps logs up to date?" # Should check for this since I don't see the message
puts "Fine naming and moving started  . . . . . . . . . . . . " # for trial runs  #{timeNowWas}

# Two names for SD cards seem common
unless File.directory?(srcSDfolder) # negative if, so if srcSDfolder exists skip, other wise change reference to …Alt
  srcSDfolder = srcSDfolderAlt
  sdCard      = sdCardAlt
end

# need to determine this based on last file and that will have to be later
srcSD = srcSDfolder + sdFolder(sdFolderFile)

if !File.exists?(downloadsFolders) # if Daguerre isn't mounted use folders on laptop. Why the negative, TODO get rid of the ! and switch the if and else
  puts "\n#{lineNum}. #{downloadsFolders} isn't mounted, so will use local folders to process"
  # Daguerre folders location loaded by default, changed as needed
  downloadsFolders = laptopDownloadsFolder
  destPhoto = laptopDestination
  destOrig  = laptopDestOrig
  srcHD = downloadsFolders
  loadingToLaptop = true
else
  puts "#{lineNum}. Using Daguerre. File.exists?(downloadsFolders (#{downloadsFolders})): #{File.exists?(downloadsFolders)}"
end

# Check if photos are already in Latest Download folder. A problem because they get reprocessed by gps coordinate adding.
folderPhotoCount = Dir.entries(destPhoto).count - 3 # -3 is a crude way to take care of ., .., .. Crude is probably OK since this isn't critical. If one real photo is there, not a big problem
if folderPhotoCount > 0
  puts "#{lineNum}. downloadsFolders: #{downloadsFolders}. Check if Pashua warning window appears"
  downloadsFolderEmpty(destPhoto, folderPhotoCount) # Pashua window
else
  puts "\n#{lineNum}. Downloads folder is empty and script will continue."
end

# Ask whether working with photo files from SD card or HD
fromWhere = whichLoc() # This is pulling in first Pashua window (1. ), SDorHD.rb which has been required
whichDrive = fromWhere["whichDrive"][0].chr # only using the first character
# puts "#{lineNum}.. whichDrive: #{whichDrive}"
# Set the return into a more friendly variable and set the src of the photos to be processed
whichOne = whichOne(whichDrive) # parsing result to get HD or SD
# puts "#{lineNum}. fromWherefromWhere: #{fromWhere}. whichDrive: #{whichDrive}. whichOne: #{whichOne}"
if whichOne=="SD" # otherwise it's HD, probably should be case for cleaner coding
  # read in last filename copied from card previously
  begin
    # Redefining to read from SD card
    lastPhotoReadTextFile = sdCard + "/lastPhotoRead.txt" # But this doesn't work if a new card. 
    puts "\n#{lineNum}. lastPhotoReadTextFile: #{lastPhotoReadTextFile}. If a new card this will be missing. What did I have in mind?"
    file = File.new(lastPhotoReadTextFile, "r")
    lastPhotoFilename = file.gets # apparently grabbing a return. maybe not the best reading method.
    puts "\n#{lineNum}. lastPhotoFilename: #{lastPhotoFilename.chop}. Value can be changed by user, so this may not be the value used."
    file.close
  # rescue Exception => err # Not good to rescue Exception
  rescue => err
    puts "Exception: #{err}. Not critical as value can be entered manually by user."
  end
  
  srcSD = srcSDfolder + lastPhotoFilename.chop.slice(1,3) + "_PANA"
# Don't know if this is needed, why not use srcSD directly
  src = srcSD
  prefsPhoto = pPashua2(src,lastPhotoFilename,destPhoto,destOrig) # calling Photo_Handling_Pashua-SD. (Titled: 2. SD card photo downloading options)
  # to get a value use prefsPhoto("theNameInFileNamingEtcPashua.rb"), nothing to do with the name above
  # puts "Prefs as set by pPashua"
  # prefsPhoto.each {|key,value| puts "#{key}:       #{value}"}
  src = prefsPhoto["srcSelect"]  + "/"
  lastPhotoFilename = prefsPhoto["lastPhoto"]
  destPhoto = prefsPhoto["destPhotoP"] + "/" # a swag since had a problem
  destOrig  = prefsPhoto["destOrig"] + "/" # without / changes file name with folder name
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

puts "\n#{lineNum}. Intialization complete. File renaming and copying/moving beginning. Time below is responding to options requests via Pashua if coping an SD card, otherwise times will be the same"

timeNowWas = timeStamp(timeNowWas)

#  If working from SD card, copy or move files to " Drag Photos HERE Drag Photos HERE" folder, then will process from there.
# puts "#{lineNum}..   src: #{src} \nsrcHD: #{srcHD}"

copySD(src, srcHD, sdFolderFile, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) if whichOne == "SD"
#  Note that file creation date is the time of copying. May want to fix this. Maybe a mv is a copy and move which is sort of a recreation. 

timeNowWas = timeStamp(timeNowWas)
puts "\n#{lineNum}. Photos will now be moved and renamed."

# puts "First will copy to the final destination where the renaming will be done and the original moved to an archive (_imported-archive folder)"
#  Only copy jpg to destPhoto if there is not a corresponding raw, but keep all taken files. With Panasonic JPG comes before RW2
copyAndMove(srcHD,destPhoto,destOrig)

# unmount card. Test if using the SD
# puts "\n#{lineNum}. fromWhere: #{fromWhere}. whichDrive: #{whichDrive}. whichOne: #{whichOne}"
whichOne =="SD" ? unmountCard(sdCard) : ""

timeNowWas = timeStamp(timeNowWas)

puts "\n#{lineNum}. Rename the photo files with date and an ID for the camera or photographer. #{timeNowWas}\n"
# tzoLoc = timeZone(fileDateTimeOriginal, timeZonesFile) # Second time this variable name is used, other is in a method
tzoLoc = - rename(destPhoto, timeZones, timeNowWas) # This also calls rename which processes the photos, but need tzoLoc value. Negative because need to subtract offset to get GMT time. E.g., 10 am PST (-8)  is 18 GMT

puts "#{lineNum} tzoLoc: #{tzoLoc}. Because GX8 and some other cameras use local time and not GMT as this script was originally written for. All photos must be in same time zone."
timeNowWas = timeStamp(timeNowWas)

puts "\n#{lineNum}. Using perl script to add gps coordinates. Will take a while as all the gps files for the year will be processed and then all the photos. -tzoLoc, `i.e.: GMT #{-tzoLoc}"

# Add GPS coordinates. Will add location later using some options depending on which country since different databases are relevant.
perlOutput = addCoordinates(destPhoto, folderGPX, gpsPhotoPerl, loadingToLaptop, tzoLoc)

timeNowWas = timeStamp(timeNowWas)

# Write timeDiff to the photo files
puts "\n#{lineNum}. Write timeDiff to the photo files"
writeTimeDiff(perlOutput)

timeNowWas = timeStamp(timeNowWas)
# Parce perlOutput and add maxTimeDiff info to photo files

# Add location information to photo file
addLocation(destPhoto, geoNamesUser)

timeNowWas = timeStamp(timeNowWas)
puts "\n#{lineNum}.-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  - All done"
