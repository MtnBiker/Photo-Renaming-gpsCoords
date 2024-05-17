#!/usr/bin/env ruby
# Set the PATH to include the Homebrew bin directory. 4/3/2024 problems with locating exiftool and this fixed it. Tried to do in .zshrc, but maybe needs a reboot? Doesn't help running in Nova
# ENV['PATH'] = '/opt/homebrew/bin:' + ENV['PATH'] Now working in 3.3.0
# Folder names use Mylio and the ones for temporary use are fine. It's just the final location that matters. And I'm trying to move them to a folder that Photos.app will watch.
# TODO camera time zones file is hard to maintain. Would a simple table or CSV be easier? Harder to setup for this Ruby script, but that's once

# Problem with File::exist in the Pashua .rb files So commented them out, see how that goes. No idea where I got the syntax from but no longer working 
# Won't run in Nova but does from command line: 
# ruby "/Users/gscar/Documents/Ruby/Photo handling/PhotoName-GPScoord-macOSphotos.rb"

# mini_exiftool couldn't be found. Was a problem with  TM_RUBY, GEM_PATH, AND GEM_HOME not matching the what TextMate is using. TM dOes not use .ruby_version

# 2023 Clock Set is Setting camera to local time which will show as FileModifyDate, DateTimeOriginal, CreateDate, SubSecCreateDate…
# TimeStamp will be offset according to camera setting for World Time which should be UTC if the zone matches the Clock Set
# This may be wrong if those settings aren't updated or even worse if one is right and the other wrong
puts "#{RUBY_DESCRIPTION} per var RUBY_DESCRIPTION. Ruby version seems to come from .irbrc if run in Nova"
puts "#{__LINE__}. Top of script. Setting variables and defining methods, and at about line no. 780 enter processing. Search for `## The \"PROGRAM\"` to find that point"

require 'fileutils'
include FileUtils
require 'find'
require 'yaml'
require "time"
require 'irb' # binding.irb where error checking is desired
require 'mini_exiftool' # have to update for new versions of Ruby. Other gems seem to be OK
# The following three requires are for geonames and then the class. Not using geonames
# require 'json'
# require 'open-uri'
# require 'addressable/template' #  gem install addressable
require 'logger'

require_relative 'lib/gpsCoordsPashua' # Dialog for adding GPS coordinates without moving
require_relative 'lib/gpsYesPashua'
require_relative 'lib/LatestDownloadsFolderEmpty_Pashua'
require_relative 'lib/Photo_Naming_Pashua-SD2'
require_relative 'lib/Photo_Naming_Pashua–HD2'
require_relative 'lib/renamePashua' # Dialog for renaming without moving
require_relative 'lib/SDorHD'
# require_relative 'lib/gpsAddLocationPashua' # Dialog for adding location information based GPS coordinates in file EXIF without moving. No longer supported
# The following lines and require 'logger' create a log file 
logger = Logger.new('logfile.log') # ChatGPT to find problems
logger.level = Logger::DEBUG

HOME = "/Users/gscar/"
thisScript = File.dirname(__FILE__) +"/" # needed because the Pashua script calling a file seemed to need the directory. 

def lineNum() # Had to move this to above the first call or it didn't work. Didn't think that was necessary. Later discovered __LINE__ and changed most.
  caller_infos = caller.first.split(":")
  # Note caller_infos[0] is file name
  caller_infos[1]
end # line numbers of this file, useful for debugging and logging info to progress screen

photosArray = [] # can create initially, but I don't know how to add other "fields" to a file already on the list. I'll be better off with an indexed data base. I suppose could delete the existing item for that index and then put in revised. Not using this, but maybe some day

sdCard = "######## No SD card ########" # mounted used in two different places and syntax may be weird
if File.exist?("/Volumes/OM SYSTEM/") ||  File.exist?("/Volumes/OM SYSTEM 1/")
  sdCard      = "/Volumes/OM SYSTEM/"
  srcSDsuffix = "OMSYS"
  puts "#{__LINE__}. #{sdCard} SD card mounted"
elsif File.exist?("/Volumes/LUMIX/")  
  sdCard      = "/Volumes/LUMIX/"
  srcSDsuffix = "_PANA"
  puts "#{__LINE__}. #{sdCard} SD card mounted"
else
  puts "\n#{__LINE__}. ######## #{sdCard} ########\n\n"
end

if sdCard == "No SD card mounted"
  puts "#{__LINE__}. Could be a problem with differently named SD cards: #{sdCard}. If the name is different, change #{__LINE__.to_i - 1}" # In 2022, I got creative and named the LUMIX cards with a suffix in numerical order.
else
  # Not sure what the following is about, but I've made a mess of this
  # lastPhotoReadTextFile = sdCard + "/DCIM/" # SD folder alternate since both this and one below occur
  # sdCardAlt   = "/Volumes/NO NAME/"
  # srcSDfolderAlt = sdCardAlt + "DCIM/" # SD folder alternate since both this and one below occur. Used at line 740
  # srcSDfolder = sdCard + "DCIM/"  # SD folder
  
  # lastPhotoReadTextFile = sdCard # I don't think this is needed here anymore # + "/DCIM/" # SD folder alternate since both this and one below occur
  # Not being used, maybe needed to deal with Lumix, but not carried out successfully or solved with lines 54ff
  # sdCardAlt   = "/Volumes/NO NAME/" # only used in the line below
  # srcSDfolderAlt = sdCardAlt + "DCIM/" # SD folder alternate since both this and one below occur. Used at line 740
  srcSDfolder = sdCard + "DCIM/"  # SD folder 
  # puts "#{__LINE__}. lastPhotoReadTextFile: #{lastPhotoReadTextFile}. If script failing may need to change the last file read to 0000 if folder change"
  puts "#{__LINE__}. srcSDfolder: #{srcSDfolder} which may or may not be the folder being read from"
end

# Temp file below that could be used to group some of the searches to geonames
photoArrayFile = thisScript + "currentData/photoArray.txt"

# Folders on laptop
laptopLocation        = HOME + "Pictures/_Photo Processing Folders/"
# laptopLocation        = File.join("Users", "gscar", "Pictures", "_Photo Processing Folders") # Should be better than above def
laptopDownloadsFolder = laptopLocation + "Download folder/"
# laptopDownloadsFolder = File.join(laptopLocation , "Download folder") # Have to go through the entire script and sort out the "/"
laptopDestination     = laptopLocation + "Processed photos to be imported to Mylio/" # a temp folder.
laptopDestOrig        = laptopLocation + "Originals to archive/" # FIXME Should be a flag to move to Daguerre when Daguerre available
laptopTempJpg         = laptopLocation + "Latest Downloads temp jpg/"
photosRenamedTo       = thisScript + "currentData/photosRenamedTo.txt" #  Had it on the SD card. How about keeping with the script? Was: HOME + "Pictures/photosRenamedTo.txt" # Should keep this on Daguerre, but not always connected.

# Folders on portable drive: Daguerre. This is the normal location with Daguerre plugged into iMac
downloadsFolders = "/Volumes/Daguerre/_Download folder/"
# Maybe should start with what computer I'm on then make decisions about what's plugged in. Also consider the 10GB as a primary?
# Process in MtnBikerSSD or Daguerre if plugged in, otherwise the computer in use which is decided later?
if File.exist?(downloadsFolders)
  puts "#{__LINE__}. Daguerre is mounted"
else
  downloadsFolders = "/Volumes/MtnBikerSSD/_Download folder/" # Obviously with MtnBikerSSD
  # downloadsFolders = "/Users/gscar/Pictures/_Photo Processing Folders/Download folder/" # MBP
  puts "#{__LINE__}. Daguerre is NOT mounted, so using #{downloadsFolders}"
end
# See at approx line 985 where decide where to move files
srcHD       = downloadsFolders + " Drag Photos HERE/"  # Photos copied from camera, sent by others, etc.
mylioStaging = downloadsFolders + "Latest Processed photos-Import to Mylio/" #  These are relabeled and GPSed files. Will be moved to Mylio after processing.
# puts "#{__LINE__}. mylioStaging: #{mylioStaging}. Where the photos are processed before being moved into Mylio folder" # debugging
tempJpg   = downloadsFolders + "Latest Downloads temp jpg/"
archiveFolder  = downloadsFolders + "_imported-archive" # folder to move originals to if not done in. No slash because getting double slash with one
srcRename = "/Volumes/Seagate 8TB Backup/Mylio_87103a/Greg Scarich’s iPhone Library/" # Frequent location to perfom this. iPhone photos brought into Mylio
srcAddLocation  = downloadsFolders + "Latest Processed photos-Import to Mylio/" # = srcRename # Change to another location for convenience. This location picked so don't screw up a bunch of files

# lastPhotoReadTextFile = thisScript + "currentData/lastPhotoRead.txt"
# puts "#{__LINE__}. lastPhotoReadTextFile: #{lastPhotoReadTextFile}. ?? But it should stored on #{sdCard} card"

# timeZonesFile = HOME + "Dropbox/scriptsEtc/Greg camera time zones.yml"
timeZonesFile = thisScript + "currentData/Greg camera time zones.yml"
# timeZones = YAML.load(File.read(timeZonesFile)) # read in that file now and get it over with. Only use once, so this just confused things
# gpsPhotoPerl = thisScript + "lib/gpsPhoto.pl" # Not using anymore 4/5/2024

# GPS log files. Will this work from laptop
folderGPX = HOME + "Documents/GPS-Maps-docs/  GPX daily logs/2024 GPX logs/" # Could make it smarter, so it knows which year it is. Massaged contains gpx files from all locations whereas Downloads doesn't. This isn't used by perl script
puts "#{__LINE__}. Must manually set folderGPX for GPX file folders. Particularly important at start of new year AND if working on photos not in current year.\n       Using: #{folderGPX}\n"

# MODULES
def filesToIgnore(item) # invisible files or .xmp that shouldn't be processed
  item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon ' or item.slice(0,7) == ".MYLock" or item.slice(-4,4) == ".xmp"
end

def gpsFilesUpToDate(folderGPX)
  # Find latest file, will have to be alphabetical order since creation date is date copied to drive.
  # Check date of file with current date, i.e. parse the file name. 
  # Compare and report.
  # Have to do after select location of files
end

def timeStamp(timeNowWas, fromWhere)  
  seconds = Time.now-timeNowWas
  minutes = seconds/60
  if minutes < 2
    report = "#{seconds.to_i} seconds"
  else
    report = "#{minutes.to_i} minutes"
  end   
  puts "\n#{fromWhere} -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -   #{report}. #{Time.now.strftime("%I:%M:%S %p")}   -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  "
  Time.now
end

def whichOne(whichOne)  # suspect could do without this with minor changes
  if whichOne =="S" # First letter of this option
    whichOne = "SD"
  # elsif whichOne == "R" # Rename
  #   whichOne = "Rename"
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

def copySD(src, srcHD, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript)
  # some of the above counter variables could be set at the beginning of this script and used locally
  puts "\n#{__LINE__}. Copying photos from an SD card starting with #{lastPhotoFilename} or from another value manually entered. \n#{Time.now.strftime("%I:%M:%S %p")}. May take a while"
  # OM starts with O and Panasonic with P, used to be hardwired for P
  # OM folder name 100OMSYS
  # Dir.glob I think can select on the beginning characters
  # Crud because assumes not changed. If OM goes back to default won't work
  globStart = lastPhotoFilename.slice(0)+"*" # Selected first letter of last file name
  # puts "#{__LINE__}. globStart: #{globStart}. Using to select folder LUMIX, but not OM. #{Time.now.strftime("%I:%M:%S %p")}. "
  cardCount = 0
  cardCountCopied = 0
  doAgain = true # name isn't great, now means do it. A no doubt crude way to run back through the copy loop if we moved to another folder.
  # timesThrough = 1
  fileSDbasename = ""
  fnp  = "" # so available outside loop?
  while doAgain==true # and timesThrough<=2 
    Dir.chdir(src) # needed for glob
    Dir.glob(globStart) do |item| # Presumably filename has globStart defined above
      cardCount += 1
      # puts src, srcHD, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript
      # break These two lines some for error checking, bu break didn't stop the script
      print(".") # crude activity bar. This doesn't happen
      # put cardCount # another try at activity bar
      # puts "#{__LINE__}.. src/item: #{src}#{item}."
      fn = src + "/" + item # 2019.05.08 added /. Hadn't had it before. Maybe the problem is with src
      fnp = srcHD + "/" + item # using srcHD as the put files here place, might cause problems later
      # get filename and make select later than already downloaded
      fileSDbasename = File.basename(item,".*")
      # puts "#{__LINE__}. #{cardCount}. item: #{item}. fn: #{fn}"
      next if item == '.' or item == '..' or fileSDbasename <= lastPhotoFilename # don't need the first two with Dir.glob, but doesn't slow things down much overall for this script
      FileUtils.copy(fn, fnp) # Copy from card to hard drive. , preserve = true gives and error. But preserve also preserves permissions, so that may not be a good thing. If care will have to manually change creation date
      cardCountCopied += 1
    end # Dir.glob("P*") do |item| 
      # write the number of the last photo copied or moved
      # if fileSDbasename ends in 999, we need to move on to the next folder, and the while should allow another go around.
    doAgain = false
    
    # The following was written for LUMIX, don't know what's going to happen with OM
    if fileSDbasename[-3,3]=="999" # and NEXT PAIRED FILE DOES NOT EXIST, then can uncomment the two last lines of this if, but may also have to start the loop over, but it seems to be OK with mid calculation change.
        nextFolderNum = fileSDbasename[-7,3].to_i + 1 # getting first three digits of filename since that is also part of the folder name
        nextFolderName = nextFolderNum.to_s + "_PANA"
        
        src = srcSDfolder + nextFolderName + "/"
        if File.exist?(src)
          doAgain = true
        else
          doAgain = false
        end     
        puts "#{__LINE__}. Now copying from #{src} as we finished copying from the previous folder LUMIX or OM (not tested).\n"
    end
  end # if doAgain…
  # Writing which file on the card we ended on
  firstLine = fileSDbasename + " was the last file read from SD card. " + Time.now.to_s # No __LINE__ because used to write this to  lastPhotoReadTextFile
  begin
    file_prepend(lastPhotoReadTextFile, firstLine)
    # Following just puts in the last file and wipes out the rest. Can delete all of this
    # fileNow = File.open(lastPhotoReadTextFile, "w") # must use explicit path, otherwise will use wherever we are are on the SD card
    #   fileNow.puts firstLine
    #   fileNow.close
      puts "\n#{__LINE__}. The last file processed. fileSDbasename, #{fileSDbasename}, written to #{fnp} ??."
  rescue IOError => e
    puts "Something went wrong. Could not write last photo read (#{fileSDbasename}) to #{fileNow}"
  end # begin
    puts "\n#{__LINE__}. Of the #{cardCount} photos on the SD card, #{cardCountCopied} were copied from #{src} to #{fnp}. Are these correct???. " # last item was src, doesn't make sense
end # copySD

def uniqueFileName(filename)
  # https://www.ruby-forum.com/topic/191831#836607
  count = 0
  unique_name = filename
  while File.exist?(unique_name)
    count += 1
    unique_name = "#{File.join(File.dirname(filename),File.basename(filename, ".*"))}-#{count}#{File.extname(filename)}"
  end
  unique_name
end

def mylioStageAndArchive(srcHD, mylioStaging, tempJpg, archiveFolder, photosArray)
  # Already copied from SD card, but copying to processing folder (mylioStaging) and then moving the original to archive folder (archiveFolder)
  puts "\n#{__LINE__}. Copy photos\nfrom #{srcHD}\n
  to #{mylioStaging} where the renaming will be done, \n
  and the originals moved to an archive folder (#{archiveFolder})" 
  # Only copy jpg to mylioStaging if there is not a corresponding raw, but keep all taken files. With Panasonic JPG comes before RW2
  # Guess this method is slow because files are being copied
  # THIS METHOD WILL NOT WORK IF THE RAW FILE FORMAT ALPHABETICALLY COMES BEFORE JPG. SHOULD MAKE THIS MORE ROBUST
  photoFinalCount = 0
  delCount = 1
  itemPrev = "" # need something for first time through
  itemPrevExtName = ""
  fnp = ""
  # puts "#{__LINE__}. Files in #{srcHD}: #{Dir.entries(srcHD).sort.reverse}" # list of files to be processed
  Dir.entries(srcHD).sort.reverse.each do |item| # This construct goes through each in order. Sometimes the files are not in order with Dir.foreach or Dir.entries without sort. Reverse sorting so can do Raws first
    # Item is the file name
    # puts "\n#{__LINE__}.. photoFinalCount: #{photoFinalCount + 1}. item: #{item}." # kind of a progress bar
    next if item == '.' or item == '..' or item == '.DS_Store'
    # next if filesToIgnore(item) == true

    fn  = srcHD + item
    fnm = mylioStaging + item
    fna = archiveFolder + item # to already imported for archiving
    itemExt = File.extname(item).downcase

    # if Raw or mp4, copy to staging
    if itemExt != ".jpg"
      # puts "#{__LINE__}. #{fn} since #{itemExt} is not jpg to be staged"
      FileUtils.copy(fn, fnm)
    end

    # If a jpg and has an effect, copy to mylioStaging via
    # ArtFilter: Off; 0; 0; 0 may be the screen
    fileEXIF = MiniExiftool.new(fn)
    filterEffect = fileEXIF.FilterEffect
    if itemExt.downcase == ".jpg" && filterEffect != "Expressive" # Expressive is default, so not much of an effect, but may need to change this
      fnt = tempJpg + item
      FileUtils.copy(fn, fnt)
      puts "#{__LINE__}. #{File.basename(fn)} staged since filterEffect is #{filterEffect} or OM-1 without support for orf yet."
    end

    # if two jpgs in a row, then no associated raw, therefore stage
    if itemExt == ".jpg" && itemPrevExtName == itemExt
      fnt = tempJpg + item
      FileUtils.copy(fn, fnt)
      puts "#{__LINE__}. #{fn} to be staged since #{itemPrevExtName} == #{itemExt} was #{itemPrevExtName == itemExt}"
    end

    itemPrevExtName = itemExt # since reusing below. jpg, orf (Olympus) or RW2 (Panasonic). So will work as long as Raw comes after jpg alphabetically

    if File.exist?(fna)  # moving the original to _imported-archive, but not writing over existing files
      fna = uniqueFileName(fna)
      FileUtils.move(fn, fna)
      puts "#{__LINE__}. A file already existed with this name so it was changed to fna: #{fna}"
    else # no copies, so move
      FileUtils.move(fn, fna)
    end # File.exist?
    # "#{__LINE__}.. #{photoFinalCount + delCount} #{fn}" # More for debugging, but maybe OK as progress in this slow process
    photoFinalCount += 1
    arrayIndex = photoFinalCount - 1 # Need spaces around the minus
    photosArray << [arrayIndex, item, fnm, itemPrevExtName] # count minus one, so indexed like an array starting at zero
    print "." # Trying to get a progress bar
  end # Dir.entries
  # puts "\#{__LINE__}. #{photoFinalCount} photos have been moved and are ready for renaming and gpsing. #{delCount-1} duplicate jpg were not
  if delCount > 1
    comment = "#{__LINE__}. #{delCount-1} jpegs were moved to #{tempJpg} for processing separately."
  else
    comment = ""
  end # if delCount
  puts "\n#{__LINE__}. #{photoFinalCount} photos have been moved and are ready for renaming and adding GPS coordinates \n#{comment}"
  return photosArray
end # mylioStageAndArchive: copy to the final destination where the renaming will be done and coordinates added; and the original moved to an archive (_imported-archive folder)

# def unmountCard(card)
#   puts "#{__LINE__}. card: #{card}"
#   card = card[-8, 7]
#   puts "#{__LINE__}. card: #{card}"
#   card  = "\"" + card + "\""
#   disk =  `diskutil list |grep #{card} 2>&1`
#   puts "\n#{__LINE__}. disk: #{disk}"
#   # Getting confused because grabbing the last 7 twice. And naming sucks (mjy fault)
#   driveID = disk[-8, 7] # not sure this syntax is precise, but it's working.
#   puts "#{__LINE__} Unmount #{card}. May have to code this better. See if card name is already a variable. This is hard coded for a specific length of card name"
#   puts "#{__LINE__}. driveID: #{driveID}. card: #{card}"
#   cmd =  "diskutil unmount #{driveID} 2>&1"
#   puts "cmd: #{cmd}"
#   unmountResult = `diskutil unmount #{driveID} 2>&1`
#   puts "\n#{__LINE__}. SD card, #{unmountResult}, unmounted."
# end #unm

def userCamCode(fn)
  fileEXIF = MiniExiftool.new(fn)
  ## not very well thought out and the order of the tests matters
  case fileEXIF.model
    when "OM-1MarkII"
      userCamCode = ".gs.O" # gs for photographer. P for *P*anasonic Lumix
    when "DMC-GX8"
      userCamCode = ".gs.P" # gs for photographer. P for *P*anasonic Lumix
    when "iPhone 13"
      userCamCode = "gs.i" # gs for photographer. i for iPhone
    when "iPhone 15"
      userCamCode = "lb.i" # gs for photographer. i for iPhone
    when "Canon PowerShot S100"
      userCamCode = ".lb" # initials of the photographer who usually shoots with the S100
    when "DMC-GX7" # no longer using, but may reprocess some photos
      userCamCode = ".gs.P" # gs for photographer. P for *P*anasonic Lumix
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

def fileAnnotate(fn, fileDateTimeOriginalstr, tzoLoc, camModel)
  # Called from rename
  # writing original filename and dateTimeOrig to the photo file.
  fileEXIF = MiniExiftool.new(fn)
  if tzoLoc.to_i < 0
    tzoLocPrint = tzoLoc
  else
    tzoLocPrint = "+" + tzoLoc.to_s
  end
  
  # Getting OM details on shooting modes
  # Birds, shooting mode
  # AFPointDetails : Birds; Face Priority; AF on Half Press; No Eye-AF; Face Detection; With MF; AF Priority; No Object found; S-AF
  # AISubjectTrackingMode : Birds; Object Not Found
  # Nothing about shooting mode except below and now StackedImage:
  if camModel == "OM-1MarkII"
    puts "#{__LINE__}. camModel: #{camModel}. fn: #{fn}. DEBUG for best formatting to work with Mylio."
    driveMode = fileEXIF.DriveMode # Focus Bracketing, Shot 12; Electronic shutter (one of the shots)
    shootingMode = driveMode.split(',')[0] # Focus Bracketing or whatever is before the first comma
    # puts "#{__LINE__}. driveMode: #{driveMode}. shootingMode: #{shootingMode}. of class: #{shootingMode.class}. DEBUG"
    shotNo = driveMode.scan(/\d+/).to_s # just the shot number. Surprised not already a string
    shootingMode = shootingMode + "-" + shotNo # Focus Bracketing-xx will be the result. Note this is 
    subjectTrackingMode = fileEXIF.AISubjectTrackingMode
    subjectTrackingModeOne = subjectTrackingMode.split(';')[0]
    shootingMode = "STM: " + subjectTrackingModeOne + ". SM:" + shootingMode
    # To see if LiveND used add info to shootingMode. Not sure this is consistent
    stackedImage = fileEXIF.StackedImage # 
    unless stackedImage == "No" # Stacked Image : No or Focus-stacked
      shootingMode = stackedImage + ". " + shootingMode
    end
    instructions = fileEXIF.instructions = "#{shootingMode}. #{File.basename(fn,".*")}" # Maybe drop basename (original file name) to make it shorter. Is available in PreservedFileName
    puts "#{__LINE__}. camModel: #{camModel}. fileEXIF.instructions: #{instructions} DEBUG"
  else
    # shootingMode = "" # all other cameras. Next line probably negates the need for this
    fileEXIF.instructions = "#{File.basename(fn)}"
    puts "#{__LINE__}. camModel: #{camModel}. fileEXIF.instructions: #{fileEXIF.instructions} DEBUG"
  end
   
  # Want original filename somewhere. Show up in PreservedFileName in Mylio, but that field DOES NOT show up in Preview. And trying to add shooting modes such as SH1 although terms are different, eg DriveMode : Continuous Shooting 
  # fileEXIF.instructions = "#{File.basename(fn)}. subjectTrackingMode. #{subjectTrackingModeOne}. shootingModes: #{shootingMode}.
   # fileEXIF.comment = "Capture date: #{fileDateTimeOriginalstr} UTC. Time zone of photo is GMT #{tzoLoc}. Comment field" # Mo show in Mylio or Preview. Does get written
  # fileEXIF.UserComment = "UserComment. Is this different that Comment. Preview as Exif UserComment. Doesn't show up in Mylio"
  # fileEXIF.ImageDescription = "ImageDescription. Shows up in Preview. Mylio as Caption, so not good for general use"
  # fileEXIF.ImageDescription = "Testing to see if ImageDescription is written and visible in Mylio" # Is written to "Caption" field in Mylio, so not good for general use
  fileEXIF.PreservedFileName = "#{File.basename(fn)}" # works but does not show up in Preview, but does in Mylio, so continue to also add to Instructions above
  fileEXIF.TimeZoneOffset = tzoLoc # Time Zone Offset, (1 or 2 values: 1. The time zone offset of DateTimeOriginal from GMT in hours, 2. If present, the time zone offset of ModifyDate)
  # Am I misusing this? I may using it as the TimeZone for photos taken GMT 0 TODO
  # OffsetTimeOriginal	(time zone for DateTimeOriginal) which may or may not be the time zone the photo was taken in TODO
  # TODO write GMT time to
  fileEXIF.save
end # fileAnnotate. writing original filename and dateTimeOrig to the photo file and cleaning up TS5 photos with bad (no) GPS data.

# With the fileDateTimeOriginal for the photo, find the time zone based on the log.
# The log is in numerical order and used as index here. The log is a YAML file
def timeZone(fileDateTimeOriginal, timeZonesFile )
  # theTimeAhead = "2050-01-01T00:00:00Z"
  # puts "#{__LINE__}. timeZones:  #{timeZones}."
  timeZones = YAML.load(File.read(timeZonesFile)) # should we do this once somewhere else? Let's try that in this new version
  # puts "#{__LINE__}. timeZones.keys:  #{timeZones.keys}."
  i = timeZones.keys.max # e.g. 505
  j = timeZones.keys.min # e.g. 488
  while i > j # make sure I really get to the end 
    theTime = timeZones[i]["timeGMT"]
    # puts "\n#{__LINE__}. (last entry in timeZonesFile) i: #{i}. theTime (of the last entry in GMT): #{theTime}. theTime.class: #{theTime.class}" # i: 502. theTime: 2011-06-29T01-00-00Z. theTime.class: String
    theTime = Time.parse(theTime) # class: time Wed Jun 29 00:00:00 -0700 2011. Time.parse only seems to do the date part
    # puts "\n#{__LINE__}. #{i}. fileDateTimeOriginal: #{fileDateTimeOriginal}. theTime (in local time): #{theTime}. fileDateTimeOriginal.class: #{fileDateTimeOriginal.class}. theTime.class: #{theTime.class}"
    # puts "Note that these dates are supposed to be UTC, but are getting my local time zone attached."
    if fileDateTimeOriginal.to_s > theTime.to_s # What if neither was to_s? TODO
      theTimeZone = timeZones[i]["zone"]
      # puts "#{__LINE__}. #{i}. fileDateTimeOriginal: #{fileDateTimeOriginal} fileDateTimeOriginal.class: #{fileDateTimeOriginal.class}. theTimeZone: #{theTimeZone}."
      return theTimeZone
    else
      i= (i.to_i-1).to_s
    end
  end # loop
  # theTimeZone = -2 # Was changed on MBP, don't know if needed there or it was a one off
  # puts "#{__LINE__}. #{i}. fileDateTimeOriginal: #{fileDateTimeOriginal} fileDateTimeOriginal.class: #{fileDateTimeOriginal.class}. theTimeZone: #{theTimeZone}. "  return theTimeZone
end # timeZone

def bracketed(fn, fileDate, driveMode, stackedImageTrue, shot_no, camModel)
  stackBracket = "-" + shot_no.to_s + "_fB"
  stackBracket = "_FS" if stackedImageTrue
  fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + stackBracket + userCamCode(fn) # only 'fileBaseName = ' to remind me how this is used
end

def oneBackTrue(src, fn, fnp, fnpPrev, subSecExists, subSec, subSecPrev, fileDate, driveMode, dupCount, camModel)
  # Some of these fields may not be needed, I was fighting the wrong problem and may have added some that aren't needed
  # puts "\n#{__LINE__}. fn: #{fn}. fnp: #{fnp}. subSecExists: #{subSecExists}. fileDate: #{fileDate}. driveMode: #{driveMode}.  dupCount: #{dupCount}. in oneBackTrue(). DEBUG"
  dupCount += 1
  # Getting sequence no./shot no. for OM-1. DriveMode is "Single Shot; Electronic shutter" for normal photos
  unless driveMode.nil? || driveMode.empty? # opposite of if, therefore if driveMode is not empty
    match = driveMode.match(/Shot (\d{1,3})/)
    shot_no = match[1].to_i if match
    
    # driveMode = fileEXIF.DriveMode
    # Also get the shooting mode from `Drive Mode : Focus Bracketing, Shot 6; Electronic shutter`
    # matches = driveMode.match(/Drive Mode\s*:\s*([^,;]+)/)  
    # if matches
    #   shootingMode = matches[1].strip
    #   puts "#{__LINE__}. shootingMode: #{shootingMode}. DEBUG"
    # else
    #   puts "#{__LINE__}. Shooting mode not found."
    #   # shootingMode = "" # if necessary to prevent errors
    # end
    shootingMode = driveMode.split(',')[0]
    # puts "#{__LINE__}. fn: #{fn}. driveMode: #{driveMode}. shot_no: #{shot_no}. shootingMode: #{shootingMode}. subSecExists: #{subSecExists}. fileDate: #{fileDate}. DEBUG"
  end
  if subSecExists # mainly GX8. and maybe iPhone bursts
    fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  subSec + userCamCode(fn) # this doesn't happen for the first one in the same second.
    # puts "#{__LINE__}. fn: #{fn} in 'if subSecExists'.     fileBaseName: #{fileBaseName}. dupCount: #{dupCount}"
    if dupCount == 1
      # Can use old fileDate because it's the same and userCamCode. 
      fnp = src + fileDate.strftime("%Y.%m.%d-%H.%M.%S") + subSecPrev + userCamCode(fn)+  File.extname(fn).downcase
      # puts "#{__LINE__}. We will relabel #{fnpPrev} to #{fnp} since it didn't get subSecPrev: #{subSecPrev}. dupCount: #{dupCount} DEBUG"
      File.rename(fnpPrev, fnp) # File.rename(oldName, newName)
    end # if dup count
  end
  if shot_no.to_i > 0 # photos without subsecs. OM-1 but with shot number.
    # Getting sequence no. for OM-1. DriveMode is "Single Shot; Electronic shutter" for normal photos
       # puts shot_no
    # End getting seqence no
    fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + "-" + shot_no.to_s + userCamCode(fn) # + filtered Why is this
    # puts "#{__LINE__}. fn: #{fn} in 'if oneBack'. fileBaseName: #{fileBaseName}. fileDate: #{fileDate}. shot_no: #{shot_no}. userCamCode(fn): #{userCamCode(fn)}. DEBUG" # .  filtered: #{filtered}
  else # photos without subsecs, pre GX8 and other OM-1 in same second
    # puts "#{__LINE__}. fn: #{fn} in 'if oneBack'. fileDate: #{fileDate}. dupCount: #{dupCount}. userCamCode(fn): #{userCamCode(fn)}. debug"
    # fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  seqLetter[dupCount] + userCamCode(fn) + filtered
    # Giving up on seqLetter because too many, use dupCount, but also add shot no. 
    
    # FIXME. I think the next 12 or so lines are not being used.
    # driveMode = fileEXIF.DriveMode # '-DriveMode : Continuous Shooting, Shot 12; Electronic shutter'
    # puts "#{__LINE__}. driveMode: #{driveMode}. driveMode.class: #{driveMode.class} for . " # error if?
    if driveMode.class == "NilClass"
      fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + "-" + dupCount.to_s + userCamCode(fn)
    elsif driveMode.length > 0
      match = driveMode.match(/Shot (\d{1,3})/)
      if match
        shot_no = match[1].to_i 
      else 
        shot_no = "FS" # for an in camera Focus Stacked image FIXME. This should not be in oneBackTrue
      end
      fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + "-" + dupCount.to_s + "(" + shot_no + ")" + userCamCode(fn)
      
      # fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + "-" + dupCount.to_s + ".FS" + userCamCode(fn) # for an in camera Focus Stacked image
    else
      puts "#{__LINE__}. driveMode: #{driveMode}. driveMode.class: #{driveMode.class}." 
      fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + "-" + dupCount.to_s  + userCamCode(fn)
    end
    
    puts "#{__LINE__}. fn: #{fn} in 'if oneBack'.     fileBaseName: #{fileBaseName}."
  end # subSecExists
  return fileBaseName
end # oneBackTrue

def rename(src, timeZonesFile, timeNowWas, photosRenamedTo)
  # src is mylioStaging folder
  # timeZonesFile is my log of which time zones I was in when
  # timeNowWas used for timing various parts of the script.
  # puts ("#{__LINE__}. in rename. src: #{src}. timeZonesFile #{timeZonesFile}. timeNowWas: #{timeNowWas}")
  # Until 2017, this assumed camera on UTC, but doesn't work well for cameras with a GPS or set to local time
  # So have to ascertain what time zone the camera is set to by other means in this script, none of them foolproof
  # 60 minutes for ~1000 photos to rename TODO ie, very slow
  fn = fnp = fnpPrev = "" # must declare variable or they won't be available everywhere in the module
  subSecPrev = subSec = ""
  fileDatePrev = ""
  dupCount = 0
  count    = 1
  tzoLoc = ""
  camModel = ""
  seqLetter = %w(a b c d e f h i j k l m n o p q r s t u v w x y z aa bb cc dd ee ff gg hh ii jj kk ll mm nn oo pp qq rr ss tt uu vv ww xx yy zz) # used when subsec doesn't exist, but failing for large sequences possible on OM-1, so maybe use sequential numbers, i.e., dupCount?. Yes
  # puts "#{__LINE__}. Entered rename and ready to enter foreach. src: #{src}"
  Dir.each_child(src) do |item| # for each photo file
    next if filesToIgnore(item) == true # skipping file when true, i.e., not a file, with each_child, this is probably redundant.
    # puts "#{__LINE__}. File skipped because already renamed, i.e., the filename starts with 20xx #{item.start_with?("20")}"
    next if item.start_with?("20") # Skipping files that have already been renamed.
    # next if item.end_with?("xmp") # Skipping .xmp files in Mylio and elsewhere. The files may become orphans. In filesToIgnore
    # puts "#{__LINE__}. #{src} " # #{timeNowWas = timeStamp(timeNowWas)}
    # puts "#{__LINE__}. #{item} will be renamed. " # #{timeNowWas = timeStamp(timeNowWas)}
    fn = src + item # long file name
    fileEXIF = MiniExiftool.new(fn) # used several times
    # fileEXIF = Exif::Data.new(fn) # see if can just make this change, probably break something. 2017.01.13 doesn't work with Raw, but developer is working it.
    camModel = fileEXIF.model # this will in general be the same for each file and the returned value will be for the last file
    stackedImage = fileEXIF.StackedImage

    # To add display for Mylio. Don't think this is needed anymore
    # Generally jpgs are not added to Mylio, but if there is a filter effect want the jpg.
    # May need to change the terminology for OM-1
    # ArtFilter: Off; 0; 0; 0 may be the screen. This is used in two places
    filtered = ""
    filterEffect = ""
    filterEffect = fileEXIF.FilterEffect
    # puts "#{__LINE__}. filterEffect: #{filterEffect}" # For Lumix, doesn't exist on OMDS
    if File.extname(item).downcase == ".jpg" && filterEffect != "Expressive" && camModel != "OM-1MarkII" # Expressive is default, so not much of an effect, but may need to change this. OM-1 photos get caught up and they should not      filtered = "_display"
    end

    # puts "#{__LINE__}.. File.file?(fn): #{File.file?(fn)}. fn: #{fn}"
    if File.file?(fn) # why is this needed. Do a check above
      # Determine the time and time zone where the photo was taken
      # puts "#{__LINE__}.. fn: #{fn}. File.ftype(fn): #{File.ftype(fn)}." #  #{timeNowWas = timeStamp(timeNowWas)}
      fileExt = File.extname(fn).tr(".","").downcase  # needed later for determining if dups at same time. Will be lowercase jpg or rw2 or whatever
      fileExtPrev = ""
      fileDateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
      # puts "#{__LINE__}. fileDateTimeOriginal = fileEXIF.dateTimeOriginal: #{fileDateTimeOriginal} of class: #{fileDateTimeOriginal.class}"
      fileSubSecTimeOriginal = fileEXIF.SubSecTimeOriginal # no error if doesn't exist and it does not in OM
      subSec = "." + fileSubSecTimeOriginal.to_s[0..1] #Truncating to 2 figs (could round but would need to make a float, divide by 10 and round or something. This should be close enough)
      subSecExists = fileEXIF.SubSecTimeOriginal.to_s.length > 2 #
      if fileDateTimeOriginal == nil 
        # TODO This probably could be cleaned up, but then normally not used, movie files don't have this field
        fileDateTimeOriginal = fileEXIF.DateCreated  # PNG don't have dateTimeOriginal
        camModel ="MISC" # Dummy value for test below
        fileDateTimeOriginal == nil ? fileDateTimeOriginal = fileEXIF.CreationDate : "" # now fixing .mov files
        fileDateTimeOriginal == nil ? fileDateTimeOriginal = fileEXIF.MediaCreateDate : "" # now fixing .mp4 files. Has other dates, but at least for iPhone mp4s the gps info exists
      end # if fileDateTimeOriginal == nil
      tzoLoc = timeZone(fileDateTimeOriginal, timeZonesFile) # the time zone the picture was taken in, doesn't say anything about what times are recorded in the photo's EXIF. I'm doing this slightly wrong, because it's using the photo's recorded date which could be either GMT or local time. But only wrong if the photo was taken too close to the time when camera changed time zones
      # puts "#{__LINE__}. #{count}. tzoLoc: #{tzoLoc} from timeZonesFile"
      
      # count == 1 | 1*100 ?  :  puts "."  Just to show one value, otherwise without if prints for each file; now prints every 100 time since this call seemed to create some line breaks and added periods.
      # Also determine Time Zone TODO and write to file OffsetTimeOriginal	(time zone for DateTimeOriginal). Either GMT or use tzoLoc if recorded in local time as determined below
      # puts "#{__LINE__}.. camModel: #{camModel}. #{tzoLoc} is the time zone where photo was taken. Script assumes GX8 on local time "
      # Could set timeChange = 0 here and remove from below except of course where it is set to something else
      timeChange =  0 # 3600 *  # setting it outside the loops below and get reset each time through. But can get changed
      # puts "#{__LINE__}. camModel: #{camModel}. fileEXIF.OffsetTimeOriginal: #{fileEXIF.OffsetTimeOriginal}"
      if camModel ==  "MISC" # MISC is for photos without fileDateTimeOriginal, e.g., movies
        # timeChange = 0
        fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
        # puts "#{__LINE__}. fileDateTimeOriginal #{fileDateTimeOriginal}. timeChange: #{timeChange} for #{camModel} meaning movies. DEBUG"
      elsif camModel == "iPhone X"  # DateTimeOriginal is in local time
        # timeChange = 0
        fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
        timeChange = (3600*tzoLoc) # previously had error capture on this. Maybe for general cases which I'm not longer covering
        fileEXIF.OffsetTimeOriginal = "GMT"
        puts "#{__LINE__}.. fileDateTimeOriginal #{fileDateTimeOriginal}. timeChange: #{timeChange} for #{camModel}" if count == 1 # just once is enough
      end # if camModel
      fileEXIF.save # only set OffsetTimeOriginal, but did do some reading.

      fileDate = fileDateTimeOriginal + timeChange.to_i # date in local time photo was taken. No idea why have to change this to i, but was nil class even though zero  
      fileDateTimeOriginalstr = fileDateTimeOriginal.to_s[0..-6]

      oneBack = fileDate == fileDatePrev && fileExt != fileExtPrev # at the moment this is meaningless because all of one type?
      
      #  '-DriveMode : Continuous Shooting, Shot 12; Electronic shutter'. This exists for OM-1 for at least some sequence shooting. Also: `SpecialMode                     : Fast, Sequence: 9, Panorama: (none)`
      # SpecialMode may be more useful since zero if not a sequence : Normal, Sequence: 0, Panorama: (none)
      # But DriveMode can tell what kind of sequence, although not sure that's needed in this script
     driveMode = fileEXIF.DriveMode # OMDS only, not in Lumix
     # DriveMode       : Focus Bracketing, Shot 8; Electronic shutter
      
     driveModeFb = driveMode.split(',')[0]
     puts "#{__LINE__}. driveModeFb: #{driveModeFb}."  #Focus Bracketing
     fBmark = ""
     if driveModeFb.to_s == "Focus Bracketing"
       # fBmark = "_fB" 
       bracketing = true
     end

      # Not using specialMode now, but as an option
      # specialMode = fileEXIF.SpecialMode

      match, shot_no = ""

      # puts "#{__LINE__}. fn: #{fn}. driveMode: #{driveMode}.\nspecialMode: #{specialMode} oneBack: #{oneBack} = true is two photos in same second. If true, oneBackTrue will be called."
      # Maybe should enter if there is a shot no.
      unless driveMode.nil? || driveMode.empty? # opposite of if, therefore if driveMode is not empty
        match = driveMode.match(/Shot (\d{1,3})/) # Getting shot no. from `Continuous Shooting, Shot 12; Electronic shutter`
        shot_no = match[1].to_i if match
        # First photo in a sequence won't get -1 in oneBackTrue.
        if shot_no.to_i == 1
          fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + "-" + shot_no.to_s + fBmark + userCamCode(fn)
          puts "#{__LINE__}. Because this was the first in a sequence a `1` was added to the filename for #{fileBaseName}. DEBUG"
        end
      end
      # puts "#{__LINE__}. oneBack: #{oneBack}. match: #{match}. DEBUG"
      # Add check for bracketing and treat as needed, then onBack and treat as needed.
      stackedImageTrue = false
       if stackedImage[0..12].to_s == "Focus-stacked"
         stackedImageTrue = true
       end
      puts "#{__LINE__} stackedImage[0..12]: #{stackedImage[0..12]}. stackedImageTrue: #{stackedImageTrue}" #  stackedImage[0..12]: Focus-stacked. stackedImageTrue: false
      if bracketing or stackedImageTrue
        fileBaseName = bracketed(fn, fileDate, driveMode, stackedImageTrue, shot_no, camModel)
      elsif oneBack # || match # Two photos in same second? 
        puts "#{__LINE__} if oneBack || match. oneBack: #{oneBack}. match: #{match}. DEBUG"
        fileBaseName = oneBackTrue(src, fn, fnp, fnpPrev, subSecExists, subSec, subSecPrev, fileDate, driveMode, dupCount, camModel)
      else # normal condition that this photo is at a different time than previous photo
        puts "#{__LINE__} if oneBack || match. oneBack: #{oneBack}. match: #{match}. DEBUG"
        dupCount = 0 # resets dupCount after having a group of photos in the same second
        fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + fBmark + userCamCode(fn) + filtered
        # puts "#{__LINE__}. item: #{item} is at different time as previous.    fileBaseName: #{fileBaseName}"
      end # if oneBack
      # end # if subSecExists
      fileDatePrev = fileDate
      fileExtPrev = fileExt
      # fileBaseNamePrev = fileBaseName
    
      fileAnnotate(fn, fileDateTimeOriginalstr, tzoLoc, camModel) # was passing fileEXIF, but saving wasn't happening, so reopen in the module?

      fnp = fnpPrev = src + fileBaseName + File.extname(fn).downcase # unless #Why was the unless here?
      # puts "Place holder to make the script work. where did the unless come from"
#       puts "#{__LINE__}. fn: #{fn}. fnp (fnpPrev): #{fnp}. subSec: #{subSec}"
      subSecPrev = subSec.to_s
      File.rename(fn,fnp)
      photoRenamed = "#{__LINE__}. photosRenamedTo: #{photosRenamedTo}. #{File.basename(fn)} was renamed to #{File.basename(fnp)}"
      begin
        file_prepend(photosRenamedTo, photoRenamed)
        # puts "#{__LINE__}. #{Time.now} #{photoRenamed}"
      rescue IOError => e
        puts "#{__LINE__}. Something went wrong. Could not write last photo renamed (#{photoRenamed}) to #{photosRenamedTo}"
      end # begin
      
      count += 1
     else
      puts "#{__LINE__}. CHECKING why `if File.file?(fn)` is needed. File.file?(fn): #{File.file?(fn)} for fn: #{fn}"
    end # 3. if File.file?(fn)
    # puts "#{__LINE__}. Got to here. tzoLoc: #{tzoLoc}"
    
  end # 2. Dir.each_child(src)
  # puts "#{__LINE__}.  A log of photo file renaming is at #{photoRenamed}. For debugging uncomment the line about 3 lines below to get the list in the running log."
   # tzoLoc the time zone the picture was taken in,
  {tzoLoc: tzoLoc, camModel: camModel} #return
end # rename ing photo files in the downloads folder and writing in original time.


def exiftoolAddCoordinates(photoFolder, folderGPX, tzoLoc)
  # Remember writing a command line command
  # --timeoffset seconds     Camera time + seconds = GMT. No default.  
  # maxTimeDiff = 50000 # seconds, default 120, but I changed it 2011.07.26 to allow for pictures taken at night but GPS off. Distance still has to be reasonable, that is the GPS had to be at the same place in the morning as the night before as set by the variable below
  # This works, put in because having problems with file locations
  # perlOutput = `perl \"#{gpsPhotoPerl.shellescape}\" --dir #{photoFolder.shellescape} --gpsdir #{folderGPX.shellescape} --timeoffset 0 --maxtimediff 50000 2>&1`
  
  # photoFolder is where the photos are that are going to have gps coordinates added. A temporary location. Usually called mylioStaging is the overall script
  # folderGPX is where the gpx tracks are
  # gpsPhotoPerl is where gpsPhoto.pl is
  # tzoLoc is the time zone from Greg camera time zones.yml file. Since GPS records UTM. Camera time zone setting varies. Camera only records the time it is set for, but doesn't accurately report the zone. Currently exiftool is saying the zone is the zone of the computer running the script. tzoLoc value can be changed in this module. tzoLoc is hours and gets changed to seconds as timeOffset for use by gpsPhoto.pl
  # <--timeoffset seconds> A positive value means that the camera is behind in time, a negative value means that the camera is ahead in time.
  
# Assuming all the photos are from the same camera, get info on one and use that information.
# GX8 is usually local time, but may get
# GX7 is UST
  camModel = ""
  timeOffset = 0
  Dir.each_child(photoFolder) do |item|
    # This is only run once, so efficiency doesn't matter
    count = 0
    # puts "#{__LINE__}. item.slice(0,4): #{item.slice(-4,4)}" # debug for following
    next if filesToIgnore(item)  # skipping file when true == true
    fn = photoFolder + item
    fileEXIF = MiniExiftool.new(fn) # used several times
    camModel = fileEXIF.model
    puts "#{__LINE__}. model: #{camModel} fn: #{fn}" # debug
    panasonicLocation = fileEXIF.location
    # timeOffset = 0 # could leave this in and remove the else 
    if File.file?(fn)
      if camModel == "OM-1MarkII"
        # CreateDate is local time with time zone noted, e.g.,  2024:03:03 15:56:50-08:00 3:15 pm in tz -8
        # Date Time UTC                   : 2024:03:03 23:56:50
        # Offset Time                     : -08:00 # so can get directly from photo
        timeOffset = -fileEXIF.OffsetTime(0..2).to_i # so how much GMT is ahead of local. So opposite time zone
        puts "#{__LINE__} timeOffset: #{timeOffset} for #{camModel}. Sign is opposite tz. -fileEXIF.OffsetTime(0..2).to_i"
      elsif camModel == "DMC-GX8" # Assumes GX8 always on local time. And TimeZone is set
        # timeOffset = tzoLoc * 3600 # old way which may be fine, but the following seems more direct. May not account for camera not being in the zone it's set for, but I don't think that matters. It matters for time labeling, but this is only GPS coords
        timeOffset =  (fileEXIF.TimeStamp -  fileEXIF.CreateDate) # seconds, so how much GMT is ahead of local. So opposite time zone
        puts "#{__LINE__} timeOffset: #{timeOffset} = (fileEXIF.TimeStamp: #{fileEXIF.TimeStamp} -  fileEXIF.CreateDate:#{fileEXIF.CreateDate}) for for #{camModel}. "
        puts "#{__LINE__}. timeOffset: #{timeOffset} seconds (#{timeOffset/3600} hours) with GX-8 photos stamped in local time. FYI: tzoLoc: #{tzoLoc} per zones file which isn't being used for coordinates but seems like it could with hrs to secs change."
        # timeOffset = -3600 * 7
        # puts "#{__LINE__}. Hardwired to #{timeOffset} seconds for this run"

      elsif camModel.include?("DMC") and panasonicLocation.length > 0 # Panasonic in Travel Mode, but also some photos exported from Photos.
        timeOffset = tzoLoc * 3600
        puts "#{__LINE__}. timeOffset: #{timeOffset} sec (#{tzoLoc} hours) with photos stamped in local time for #{camModel}."
      # elsif camModel  == "DMC-TS5"
    #     # Offset sign is same as GMT offset, eg, we are -8, but need to increase the time to match UST, therefore negative
    #     timeOffset = - fileEXIF.dateTimeOriginal.utc_offset # Time zone is set in camera, i.e. local time in this case
    #     # What does utc_offset do for the above. dateTimeOriginal is just a time, e.g., 2018:12:31 21:38:32, which is the time the camera thinks it is. Camera doesn't know about zone. Camera may, but from dateTimeOriginal, can't tell the time zone.
    #     puts "#{__LINE__}. timeOffset: #{timeOffset} for DMC-TS5 photos stamped in local time."
    #   else # GX7 time is UTC. iPhone ends up here too
    #     timeOffset = 0 # camelCase, but perl variable is lowercase
    #     puts "#{__LINE__}. timeOffset: #{timeOffset} sec (#{tzoLoc} hours) with photos stamped in GMT"
      end # if camModel
      # puts "#{__LINE__} timeOffset: #{timeOffset} triple checking"
      fileEXIF.save 
      count += 1
    end # if File.file
    break if count == 1 # once have a real photo file, can get out of this. Only check this once
  end # Dir.foreach
  puts "#{__LINE__}. timeOffset: #{timeOffset}. camModel: #{camModel}. All photos must be same camera and time zone or photos may be mislabeled and geo-located."
   
  puts "\n#{__LINE__}. Variables input to exiftool for GPS annotating for DEBUGing:"
  puts "photoFolder: #{photoFolder}\nfolderGPX: #{folderGPX}\ntimeoffset: #{timeOffset}"
  puts "\n#{__LINE__}. Finding all gps points from all the gpx files using exiftool and adding GPS info to each photo file. This may take a while.\n"
  puts "#{__LINE__}.========= Beginning of  exiftool geotag ==========  #{Time.now.strftime("%I:%M:%S %p")}\n"
  gpxLogs = folderGPX + "/*.gpx" # to get multiple files in the folder
  
  # puts "#{__LINE__}. Don't build a command line as a string. For example: system('exiftool', '-Camera:DriveMode', filename). Similar approaches work with Open3. If you do it like that then you won't launch a shell and you won't have to deal with the shell's quoting and escaping problems\n, if you give at least one argument besides the program name to the function, the shell is not invoked."
  
  # subcommands = "-overwrite_original -if 'not $gpslatitude'"
  # Ignored superfluous tag name or invalid option: -overwrite_original -if 'not $gpslatitude'
  # exiftoolGps = system("exiftool", "-geotag",  "#{gpxLogs}", "#{photoFolder}", "-overwrite_original -if 'not $gpslatitude'") # returns true or?
  # exiftoolGps = system("exiftool", "-geotag",  "#{gpxLogs}", "#{photoFolder}", "#{subcommands}") # Invalid TAG name: "overwrite_original -if 'not $gpslatitude'" / Ignored superfluous tag name or invalid option: -overwrite_original -if 'not $gpslatitude'
  # exiftoolGps = system("exiftool", "-geotag",  "#{gpxLogs}", "#{photoFolder}", "-overwrite_original -if not $gpslatitude") # Invalid TAG name: "overwrite_original -if not $gpslatitude" as expected
  # exiftoolGps = system("exiftool", "-geotag",  "#{gpxLogs}", "#{photoFolder}", "-overwrite_original", " -if 'not $gpslatitude'") # No matching file found for -geotag option
  # exiftoolGps = system("exiftool", "-geotag",  "#{gpxLogs}", "#{photoFolder}", "-overwrite_original -if " , "'not $gpslatitude'") #Invalid TAG name: "overwrite_original -if " / No matching file found for -geotag option
  puts "\n#{__LINE__}. Any existing geotags will be overwritten until I can figure out how to add -if 'not $gpslatitude')"
  exiftoolGps = system("exiftool", "-geotag",  "#{gpxLogs}", "#{photoFolder}", "-overwrite_original") # will overwrite existing tags
  puts "#{__LINE__}. exiftool geotag finished #{Time.now.strftime("%I:%M:%S %p")}"
  puts "\n#{__LINE__}======== End of exiftool geotag ==========  #{Time.now.strftime("%I:%M:%S %p")}\n"
  # return exiftoolGps # return is true unless want to get the notes, but they show in script results
end # exiftoolAddCoordinates

def writeTimeDiff(perlOutput)
  perlOutput.each_line do |line|
    if line =~ /timediff=/
      fn = $`.split(",")[0]
      timeDiff = $'.split(" ")[0]
      puts "\n#{__LINE__}. #{fn} timeDiff: #{timeDiff}"
      fileEXIF = MiniExiftool.new(fn)
      fileEXIF.usageterms = "#{sprintf '%.0f', timeDiff} seconds from nearest GPS point"
      fileEXIF.save
    end
  end
end #  Write timeDiff to the photo files

def file_prepend(file, str)
  # For adding the last photo processed to beginning of file.
  # https://stackoverflow.com/questions/8623231/prepend-a-single-line-to-file-with-ruby Copied
  new_contents = ""
  str = str + "\n" # not in original, but needed to put this return in somewhere
  File.open(file, 'r') do |fd|
    contents = fd.read
    new_contents = str << contents
  end
  # Overwrite file but now with prepended string on it
  File.open(file, 'w') do |fd| 
    fd.write(new_contents)
  end
end
# puts "#{__LINE__}. mylioStaging: #{mylioStaging}" # debugging
def moveToMylio(mylioStaging, mylioFolder, timeNowWas)
  puts "\n#{__LINE__}. Moving processed photos from #{mylioStaging} to Mylio folder #{mylioFolder}"
  Dir.each_child(mylioStaging) do |item|
    fn  = mylioStaging + item # mylioStaging is now temporary destination, so nomenclature is weird
    fnp = mylioFolder + item
    # puts "#{__LINE__}.#{jpgsMovedCount += 1}. #{fn} moved to #{fnp}" # dubugging
    next if filesToIgnore(item) == true # skipping file when . or ..
    FileUtils.move(fn, fnp)
  end
  puts "Photos moved to Mylio folder, #{mylioFolder}, where they will automagically be imported into Mylio."
  puts "All done! #{timeNowWas}"
end

## The "PROGRAM" ############ ##################### ###################### ##################### ##########################
timeNowWas = timeStamp(Time.now, lineNum) # Initializing. Later calls are different
# timeNowWas = timeStamp(timeNowWas)

puts "\n#{__LINE__}. GPS file available for adding coordinates to photos."
# Was Dir.each_child(folderGPX) {|x| puts "#{__LINE__}. GPX file available #{x}" }
Dir.each_child(folderGPX) do |item| # for each photo file
  next if filesToIgnore(item) == true # skipping file when true, i.e., not a file or xmp
  # next if item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon ' or item.slice(0,7) == ".MYLock" or item.slice(-4,4) == ".xmp"
  # next if item.start_with?("20") # Skipping files that have already been renamed.
  # next if item.end_with?("xmp") # Skipping .xmp files in Mylio and elsewhere. The files may become orphans. should be included in filesToIgnore
  next if item.start_with?("not") # There is a note/file with that name in the folder
  puts "#{item}"
end

# puts "#{__LINE__}. (an alternative to the above): #{Dir.each_child(folderGPX}." # except causes and erro
puts "\n#{__LINE__}. Are the gps logs needed listed above in #{folderGPX}?\n\n" # Should check for this since I don't see the message

# Two names for SD cards seem common. Is this needed anymore? Caused an error
# unless File.directory?(srcSDfolder) # negative if, so if srcSDfolder exists skip, other wise change reference to …Alt
#   srcSDfolder = srcSDfolderAlt
#   sdCard      = sdCardAlt
# end

# need to determine this based on last file and that will have to be later Which has been done so commented out 2019.07.20
# srcSD = srcSDfolder + sdFolder(sdFolderFile)

# if Daguerre isn't mounted use folders on laptop. 
if File.exist?(downloadsFolders)
  puts "#{__LINE__}. Using Daguerre or MtnBikerSSD. File.exist?(downloadsFolders (#{downloadsFolders})): #{File.exist?(downloadsFolders)}"
else
   puts "\n#{__LINE__}. #{downloadsFolders} isn't mounted, so will use local laptop folders to process"
  # Daguerre folders location loaded by default, changed as needed
  downloadsFolders = laptopDownloadsFolder # line ~844
  mylioStaging     = laptopDestination
  archiveFolder    = laptopDestOrig
  tempJpg          = laptopTempJpg
  srcHD            = downloadsFolders # is this being used?
  # loadingToLaptop = true # No longer used
end
 # puts "#{__LINE__}. Temporary for error checking. mylioStaging: #{mylioStaging}"
 # puts "# Won't run in Nova but does from command line: See line ~10 for command"
 # puts "#{__LINE__}. Temporary for error checking. mylioStaging: #{mylioStaging}.  File.exist?(mylioStaging): #{File.exist?(mylioStaging)}" 
 # puts "\n#{__LINE__}. Crashing at next line in Nova, can run script TextMate or from command line:\n ruby \"/Users/gscar/Documents/Ruby/Photo handling/PhotoName-GPScoord-macOSphotos.rb\""
 puts "#{__LINE__}. Logging errors for the offending command in NOVA.
  File is logfile.log in  #{__FILE__}\n"

 begin
  Dir.each_child(mylioStaging) {|x| puts "#{__LINE__}. File #{x} already in #{mylioStaging}. Tells which files need to be removed?" } # Task “Custom Task” exited with a non-zero exit status: 1., but runs from command line
 rescue => e
   logger.error("An error occurred: #{e.message}")
   logger.error(e.backtrace.join("\n"))
 ensure
   logger.close
 end

 # puts "#{__LINE__}. Temporary for error checking. Dir.entries(mylioStaging): #{Dir.entries(mylioStaging)}" # Task “Custom Task” exited with a non-zero exit status: 1. and from terminal: No such file or directory @ dir_initialize - mylioStaging (Errno::ENOENT)
 # puts "#{__LINE__}. Temporary for error checking. mylioStaging: #{mylioStaging}. Dir.entries(mylioStaging).count: #{Dir.entries(mylioStaging).count}"
# Check if photos are already in Latest Download folder. A problem because they get reprocessed by gps coordinate adding.
folderPhotoCount = Dir.entries(mylioStaging).count - 3 # -3 is a crude way to take care of ., .., .. Crude is probably OK since this isn't critical. If one real photo is there, not a big problem
# puts "#{__LINE__}. Temporary for error checking. folderPhotoCount: #{folderPhotoCount}"
if folderPhotoCount > 0
  # puts "#{__LINE__}. Temporary for error checking"
  # puts "#{__LINE__}. downloadsFolders: #{downloadsFolders}. Check if Pashua warning window appears"
  # downloadsFolderEmpty(mylioStaging, folderPhotoCount) # Pashua window
else
  puts "\n#{__LINE__}. 'Processed photos to be imported to Mylio/' folder is empty and script will continue."
  puts "If script stops here, check Pashua, not going back"
end
# Ask whether working with photo files from SD card or HD
# fromWhere are the photos?
fromWhere = whichLoc(sdCard) # This is pulling in first Pashua window (1. ), SDorHD.rb which has been required # 
# puts "#{__LINE__}. fromWhere: #{fromWhere}" #{"rename"=>"1", "whichDrive"=>"SD card to be selected in the next window", "gpsLocation"=>"0", "gpsCoords"=>"0", "cb"=>"0"}
# puts "\n#{__LINE__}. fromWhere[\"rename\"]: #{fromWhere["rename"]}"
# puts "#{__LINE__}. fromWhere[\"gpsCoords\"]: #{fromWhere["gpsCoords"]}"
# puts "#{__LINE__}. fromWhere[\"gpsLocation\"]: #{fromWhere["gpsLocation"]}"
whichDrive = fromWhere["whichDrive"][0].chr # only using the first character
# A: already downloaded. S: SD card. 
# puts "\n#{__LINE__}.. whichDrive: #{whichDrive}. (A: already downloaded. S: SD card.)" #\nWill convert to SD or HD
# Set the return into a more friendly variable and set the src of the photos to be processed
whichOne = whichOne(whichDrive) # parsing result to get HD or SD
# puts "#{__LINE__}. fromWherefromWhere: #{fromWhere}. whichDrive: #{whichDrive}. whichOne: #{whichOne}" # fromWhere not defined
# Only rename files in place and skip the rest. Not sure right location because not sure about when Pashua is run
# puts "#{__LINE__}. whichOne: #{whichOne}" # debug
# # puts whichLoc()

# Getting the folder selected in the dialog box, but also sending the default

# Three options for partial processing, then go to either HD or SD
# Option for renaming files while not moving photos
# Now the logic is a mess, since for the three options below we stop and don't do any of the rest
if fromWhere["rename"] == "1" # Renaming only or could use if whichOne == "Rename"
  renameFolder = renameGUI(srcRename) 
  srcRename = renameFolder["srcSelect"].to_s  + "/" # Name in dialog box which may be different than default
  puts "\n#{__LINE__}. Photos in #{srcRename} will be renamed using date and time."
  rename(srcRename, timeZonesFile, timeNowWas, photosRenamedTo)
  # abort # break gives compile error
  abort if (whichDrive == "R") # break doesn't work, but abort seems to
end

# Option for adding GPS coordinates while not moving photos
if fromWhere["gpsCoords"] == "1"
  # srcGpsAdd folder with photos to add gps coordinates
  srcGpsAdd = gpsCoordsGUI(srcGpsAdd) # Puts up dialog box, sends default file location and retrieves selected file location
  srcGpsAdd = srcGpsAdd["srcSelect"].to_s  + "/" # Name in dialog box which may be different than default
  puts "\n#{__LINE__}. Photos in #{srcGpsAdd} will have GPS coordinates added in place."
  # puts "PAY ATTENTION TO YEAR AS NOT SURE MORE THAN ONE YEAR IS INCLUDED IN MY MODULE" # What is this for?
  # Need to find date of a file so know what part of timeZonesFile to use
  # Use to find first photo in folder and get fileDateTimeOriginal
  fileDateTimeOriginal = ""
  Dir.each_child(srcGpsAdd) do |item| # for each photo file
    next if filesToIgnore(item) == true # skipping file when true, i.e., not a file
    # puts "#{__LINE__}. File skipped because already renamed, i.e., the filename starts with 20xx #{item.start_with?("20")}"
    next if item.start_with?("20") # Skipping files that have already been renamed.
    next if item.end_with?("xmp") # Skipping .xmp files in Mylio and elsewhere. The files may become orphans
    fn = src + item # long file name
    fileEXIF = MiniExiftool.new(fn) # used several times
    fileDateTimeOriginal = fileEXIF.dateTimeOriginal
    break # stop once get to first file in folder.
  end
  tzoLoc = timeZone(fileDateTimeOriginal, timeZonesFile)
  # puts "#{__LINE__} Debugging.\n srcGpsAdd: #{srcGpsAdd} \n folderGPX: #{folderGPX}  \n gpsPhotoPerl: #{gpsPhotoPerl}  \n tzoLoc: #{tzoLoc}"
  # perlOutput = addCoordinates(srcGpsAdd, folderGPX, gpsPhotoPerl, tzoLoc)
  addGpsCoordinates = exiftoolAddCoordinates(mylioStaging, folderGPX, tzoLoc) # not using addGpsCoordinates = 
  puts "#{__LINE__}. Added coordinates to photos in #{srcGpsAdd}" # \nMultiline perlOutput follows:\n#{perlOutput}" # doing this in the addCoordinates()
  abort # break gives compile error
  # abort if (whichDrive == "R") # break doesn't work, but abort seems to
end

# Option for adding location information based on GPS coordinates while not moving photos. An option in the first dialog window, haven't used in long time
# if fromWhere["gpsLocation"] == "1"
#   srcAddLocation = addLocationGUI(srcAddLocation)  # Puts up dialog box, sends default file location and retrieves selected file location. reusing variable. One above made new temporary variable
#   srcAddLocation = srcAddLocation["srcSelect"].to_s  + "/" # Name in dialog box which may be different than default
#   puts "\n#{__LINE__}. NOT IMPLEMENTED. Photos in #{srcAddLocation} will have location information added based on GPS coordinates in EXIF data without moving the file. NOT IMPLEMENTED."
#   puts "#{__LINE__}. Need to confirm that the following works. May need to change year of folder for gpx tracks"
#   addLocation(srcAddLocation, geoNamesUser)
#   abort # break gives compile error
#   # abort if (whichDrive == "R") # break doesn't work, but abort seems to
# end

lastPhotoReadTextFile = sdCard + "lastPhotoRead.txt"
# if File.exist?(lastPhotoReadTextFile) # If SD card not mounted. TODO logic with else to try again

if whichOne=="SD" # otherwise it's HD, probably should be case for cleaner coding
  # if File.exist?(lastPhotoReadTextFile) # If SD card not mounted. TODO logic with else to try again
  # TODO Put up a dialog to remind to mount the SD card and return to here.
  # read in last filename copied from card previously
  begin
    # Read from SD card
    # lastPhotoReadTextFile = sdCard + "/lastPhotoRead.txt" # But this doesn't work if a new card.
    puts "\n#{__LINE__}. lastPhotoReadTextFile: #{lastPhotoReadTextFile}. NEED an error here if card not mounted!!. Have a kludge fix in the next rescue."
    file = File.new(lastPhotoReadTextFile, "r") # This causes an error when reading from computer
    # puts  "\n#{__LINE__}. file: #{file} DEBUG. Are we getting to here?. No so error on above line when reading from camera"
    lastPhotoFilename = file.gets # apparently grabbing a return. maybe not the best reading method.
    # lastPhotoFilename  = lastPhotoFilename.chop
    # puts "\n#{__LINE__}. lastPhotoFilename: #{lastPhotoFilename}. Value can be changed by user, so this may not be the value used. was #lastPhotoFilename.chop"
    # lastPhotoFilename is 8 characters long (P plus 7 digits) - starts with ) for OM (at least I try to remember to set it to that. Default is P (which I liked to think was Panasonic, but maybe it means photo)).
    # Adding date to this line, so will take first 12 characters (would be cleaner if made the write an array or json and worked with that, but this is the quick and dirty)
    lastPhotoFilename = lastPhotoFilename[0..7]
    puts "\n#{__LINE__}. lastPhotoFilename: #{lastPhotoFilename}. Value can be changed by user, so this may not be the value used. #{timeNowWas = timeStamp(timeNowWas, lineNum)}" # was #lastPhotoFilename.chop
    file.close
  rescue => err
    puts "Exception: #{err}. Not critical as value can be entered manually by user, but needs FIXME. Doesn't work when run from Nova. `Exception: Operation not permitted @ rb_sysopen`.\n"
  end

# Lumix folder naming: /Volumes/LUMIX/DCIM/123_PANA/ # digits are same as first three numbers in file name
# OMDS folder  naming: /Volumes/OM SYSTEM/DCIM/100OMSYS/ # seems not related to filename in general. OM has more file and folder naming options
  puts "/n#{__LINE__}. srcSDfolder: #{srcSDfolder}.  srcSDsuffix: #{srcSDsuffix}" # srcSDfolder: /Volumes/OM SYSTEM/DCIM/.  srcSDsuffix: OMSYS
  begin
    if srcSDsuffix == "OMSYS"
      srcSD = "/Volumes/OM SYSTEM/DCIM/100OMSYS"
    else # LUMIX
      srcSD = srcSDfolder + lastPhotoFilename.chop.slice(1,3) + srcSDsuffix
    end
  rescue Exception => e
    puts "#{__LINE__} +++++++++++++ SD card not available, so will EXIT.++++++++++. Probably selected wrong option."
    exit
  end
  puts "#{__LINE__}. srcSD: #{srcSD}" # srcSD: /Volumes/OM SYSTEM/DCIM/325OMSYS. Needs to be /Volumes/OM SYSTEM/DCIM/100OMSYS

# Don't know if this is needed, why not use srcSD directly. src is used in copySD at ~lineNo 880
  src = srcSD
  prefsPhoto = pPashua2(srcSD,lastPhotoFilename,mylioStaging,archiveFolder) # calling Photo_Naming_Pashua-SD2. (Titled: 2. SD card photo downloading options)
  # to get a value use prefsPhoto("theNameInFileNamingEtcPashua.rb"), nothing to do with the name above
  # puts "Prefs as set by pPashua"
  # prefsPhoto.each {|key,value| puts "#{key}:       #{value}"}
else # whichOne=="HD", but what
  src = srcHD
  # puts "#{__LINE__}. `srcHD`: #{src}. Does it have a slash?"
  prefsPhoto = pGUI(src, mylioStaging, archiveFolder) # is this only sending values in? 
  # to get a value use prefsPhoto("theNameInFileNamingEtcPashue.rb"), nothing to do with the name above
  # puts "Prefs as set by pGUI"
  # prefsPhoto.each {|key,value| puts "#{key}:       #{value}"}
  src = prefsPhoto["srcSelect"].to_s  + "/"
  # puts "#{__LINE__}. src: #{src}. Does it have a slash?"
end # whichOne=="SD"
# else
#   puts "#{__LINE__}. SD card not mounted. (=== Some logic so can mount and try again. ===)"
#   abort
# end #SD card mounted

mylioStaging = prefsPhoto["destPhotoP"].to_s + "/"
# puts "#{__LINE__}. mylioStaging: #{mylioStaging} from Pashua" # debugging

archiveFolder = prefsPhoto["destOrig"].to_s + "/"
# Above are true whether SD or from another folder

# But first check that mylioStaging is empty. I'm assuming mylioStaging has been determined at this point
mylioStagingCount = Dir.entries(mylioStaging).count
if mylioStagingCount > 3
  puts "\n#{__LINE__}. #{mylioStagingCount} files are in the destination folder"
  # Put up a notice or ask if want to delete them. Or list the first few
end

puts "\n#{__LINE__}. Initialization complete. File renaming and copying/moving beginning.\n        Time below is responding to options requests via Pashua if copying an SD card, otherwise the two times will be the same."
puts "\n#{__LINE__}. When a gpx file starting with '202' is added to Downloads they are moved to GPX logs folder by an Automator Action named 'Move my gpx tracking to GPX logs.'"


timeNowWas = timeStamp(timeNowWas, lineNum)

#  If working from SD card, copy or move files to " Drag Photos HERE Drag Photos HERE" folder, then will process from there.
puts "#{__LINE__}. src: #{src} \n      srcHD: #{srcHD}"

copySD(srcSD, srcHD, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) if whichOne == "SD"
#  Note that file creation date is the time of copying. May want to fix this. Maybe a mv is a copy and move which is sort of a recreation. 

timeNowWas = timeStamp(timeNowWas, lineNum)

puts "\n#{__LINE__}. Photos will now be copied and moved in readiness for renaming, etc."

# COPY AND MOVE and sort jpgs
# Which drive has already been decided. (this note because it hadn't yet if Daguerre wasn't available)

# puts "#{__LINE__}. mylioStaging: #{mylioStaging}" # debugging
photosArray = mylioStageAndArchive(srcHD, mylioStaging, tempJpg, archiveFolder, photosArray)
# Now do the same for the jpg files. Going to tempJpg and moving files to same places, except no jpg's will move to tempJpg

# photosArray = mylioStageAndArchive(tempJpg, mylioStaging, tempJpg, archiveFolder, photosArray)
# puts "#{__LINE__}. photosArray:" # Arrays seem to get mixed up if put in a {}
# puts photosArray
#  To see how it looks
puts "\n#{__LINE__}. photosArray[2]: #{photosArray[2]}. Sample of photosArray. NEEDS to have dateTimeStamp if to be useful, which it doesn't now." # Shows everything
# puts "photosArray[2]: " + photosArray[2] # only the index (3) shows up, not now
puts "#{__LINE__}. Next should write photosArray to #{photoArrayFile}. Turned off now since not using"
# File.write(photoArrayFile, photosArray) # A list of all the files processed. Saved with script. Work with this later
# unmount card. Test if using the SD
# puts "\n#{__LINE__}. fromWhere: #{fromWhere}. whichDrive: #{whichDrive}. whichOne: #{whichOne}"
# whichOne =="SD" ? unmountCard(sdCard) : "" # not working so turned off TODO

# timeNowWas = timeStamp(timeNowWas, ) # moved into line below

puts "\n#{__LINE__}. Photos will now be renamed. #{timeNowWas = timeStamp(timeNowWas, lineNum)}"

puts "\n#{__LINE__}. Rename [tzoLoc = rename(…)] the photo files with date and an ID for the camera or photographer (except for the paired jpgs in #{tempJpg}). #{timeNowWas}\n"
# tzoLoc = timeZone(fileDateTimeOriginal, timeZonesFile) # Second time this variable name is used, other is in a method
# RENAME Raw
puts "#{__LINE__}. mylioStaging: #{mylioStaging}. Renaming photo files with date-time. Failing with this call to rename()\n\n" # debugging

renameReturn = rename(mylioStaging, timeZonesFile, timeNowWas, photosRenamedTo) # This also calls rename which processes the photos, but need tzoLoc value. Negative because need to subtract offset to get GMT time. E.g., 10 am PST (-8)  is 18 GMT

# tzoLoc, = means the first value in the array returned
tzoLoc  = -renameReturn[:tzoLoc].to_i
camModel = renameReturn[:camModel]
timeNowWas = timeStamp(timeNowWas, lineNum)
#Rename the jpgs and then move to Latest Download
puts "\n#{__LINE__}. Rename the jpgs in #{tempJpg} and then move to #{mylioStaging}. #{timeNowWas}"
rename(tempJpg, timeZonesFile, timeNowWas, photosRenamedTo)
#  Move the jpgs to mylioStaging (Latest Download)
jpgsMovedCount = 0 # Initializing for debugging puts
Dir.each_child(tempJpg) do |item|
  next if filesToIgnore(item) == true
  fn  = tempJpg   + item # sourced from temporary storage for jpgs 
  fnp = mylioStaging + item # new jpg file in Latest Download
  # puts "#{__LINE__}.#{jpgsMovedCount += 1}. #{fn} moved to #{fnp}" # dubugging
  FileUtils.move(fn, fnp)
end

timeNowWas = timeStamp(timeNowWas, lineNum)

puts "\n#{__LINE__}. Using exiftool to add gps coordinates. Will take a while as all the gps files for the year will be processed and then all the photos. -tzoLoc, `i.e.: GMT #{-tzoLoc}"

puts "\n#{__LINE__} tzoLoc: #{tzoLoc}. Because GX8 and some other cameras use local time and not GMT as this script was originally written for. All photos must be in same time zone."
# Add GPS coordinates.
# perlOutput = addCoordinates(mylioStaging, folderGPX, gpsPhotoPerl, tzoLoc)
addGpsCoordinates = exiftoolAddCoordinates(mylioStaging, folderGPX, tzoLoc) # not using `addGpsCoordinates = `

timeNowWas = timeStamp(timeNowWas, lineNum)

# Write timeDiff to the photo files
puts "\n#{__LINE__}. Write timeDiff to the photo files NOT. Don't know if exiftool does this or do in exiftoolAddCoordinates"
# writeTimeDiff(addGpsCoordinates)

timeNowWas = timeStamp(timeNowWas, lineNum)
# Parce perlOutput and add maxTimeDiff info to photo files

puts "\n#{__LINE__}.Finished with writing timeDiff. Now move files. Note that \"Adding location information to photo files\" is commented out, i.e., geographic descriptions not being added, because Mylio finds this info."

# Move to Mylio folder (can't process in this folder or Mylio might import before changes are made)
# mylioFolder = watchedFolderForImport # Used with Photos app
# Set for OM, can I check for options depending on camera?
mylioFolder = HOME + "Mylio/Mylio Main Library Folder/2024/" # move to here unless one of the following
case camModel
when  "OM-1MarkII"
  mylioFolder = mylioFolder + "OM-1-2024/" # ANNUALLY: ADD IN MYLIO, NOT IN FINDER. Good on both iMac and MBP M1 although it's not under iCloud, so requires Mylio for syncing. Not being used
when "DMC-GX8"
  mylioFolder = mylioFolder + "GX8-2024/"
end
moveToMylio(mylioStaging, mylioFolder, timeNowWas)

# timeNowWas = timeStamp(timeNowWas, lineNum)
# puts "\n#{__LINE__}.-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  - All done"
