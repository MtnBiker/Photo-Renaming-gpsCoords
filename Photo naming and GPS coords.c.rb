#!/usr/bin/env ruby
# does not work with 1.9.3-p429 on iMac nor Laptop. make sure "rbenv local system" for the folder
# Works partially with 2.0 2013.12.27 Initial transfer, 

require 'rubygems' # # Needed by rbosa, mini_exiftool, and maybe by appscript. Not needed if correct path set somewhere.
require 'mini_exiftool' # Requires Ruby ≥1.9. A wrapper for the Perl ExifTool
require 'fileutils'
include FileUtils
require 'find'
require 'yaml'
require "time"
# The following require's are my Ruby scripts. The one's above are available online or part of the ruby installation
# require '/lib/SDorHD'
# require './lib/Photo_Naming_Pashua-SD'
# require './lib/Photo_Naming_Pashua–HD'
# require './lib/gpsYesPashua'

# Can get rid of this unless when upgrade to ruby v2 or is it v1.9
# unless Kernel.respond_to?(:require_relative)
#   module Kernel
#     def require_relative(path)
#       require File.join(File.dirname(caller.first), path.to_str)
#     end
#   end
# end
require_relative 'lib/SDorHD'
require_relative 'lib/Photo_Naming_Pashua-SD'
require_relative 'lib/Photo_Naming_Pashua–HD'
require_relative 'lib/gpsYesPashua'

puts "RUBY_DESCRIPTION: #{RUBY_DESCRIPTION}\n\n" # 2013.06.09 v1.8.7


# prefs. Most of these could be eliminated as they are always done
lastPhotoFilename = ""
movePhotoYN   =  false # Deprecated for photoHandling . For testing or depending on how being used. Seems to be not being used. Set to false
photoHandling =  "C" # C[opy], M[ove], R[ename], N[o] for testing or to preview the images. See defPhoto() for more information
movieHandling =  "C" # C[opy], M[ove], R[ename], N[o] for testing or to preview the images.
addGPS2photos = true # true or false. Try to add gps location to photo files
srcSDfolder = "/Volumes/NO NAME/DCIM/" # Panasonic and probably Canon
srcHD = "/Volumes/Knobby Aperture II/_Download folder/ Drag Photos HERE/"  # trailing slash is added because Pashua doesn't pick it up. Photos copied from original location such as camera or sent by others
#  srcHD is where photos copied to from SD card, might need to make this a different variable
#  the two above are set to src when select in first Pashua window
# $srcPhoto = src # to bring variable into Pashua ### Change to mounted card when get detection built in FIX
thisScript = File.dirname(__FILE__) +"/" # needed because the Pashua script calling a file seemed to need the directory. 
# thisScript = "/Users/gscar/Dropbox/scriptsEtc/Photo renaming, movie, gps-Current/" # needed because the Pashua script calling a file seemed to need the directory.
#  also use thisScript to give explicit path for other files
destPhoto = "/Volumes/Knobby Aperture II/_Download folder/Latest Download/" #  These are relabeled and GPSed files.
destOrig  = "/Volumes/Knobby Aperture II/_Download folder/_already imported/" # folder to move originals to if not done in 
destDup   = "/Volumes/Knobby Aperture II/_Download folder/Latest Download dups/" # Shouldn't be needed, but might if rerun
destNoCoords = "/Volumes/Knobby Aperture II/_Download folder/Latest Download no coordinates/"
destOrig = "/Volumes/Knobby Aperture II/_Download folder/_already imported/" # folder to move originals to if not done in place or deleted
destMovie = destPhoto
# destMovie = "/Volumes/Knobby Aperture Disk/Photos-digital/_Download folder/Latest Movie Download/" # final folder for movies. Mar. 2010: same folder as photos since Aperture 3 can handle
geoInfoMethod = "wikipedia" # for gpsPhoto to select georeferencing source. wikipedia—most general and osm—maybe better for cities
gpsPhotoLoc = "gpsPhoto.pl" # Perl script that puts gps locations into the photos. SEEMS TO WORK WITHOUT ./lib ????
timeZonesFile = "Greg camera time zones.yml" # Kept in Dropbox so can update on the road..
lastPhotoReadTextFile = "currentData/lastPhotoRead.txt"
sdFolderFile = "/Users/gscar/Documents/Ruby/Photo handling/currentData/SDfolder.txt" # shouldn't need full path
# gpsPhoto.pl related. Only written to work with daily files stored by units such as Garmin 60CSx
# location of gpx files
folderGPX = "/Users/gscar/Documents/GPS-Maps-docs/   Garmin gpx daily logs/" # Inside this folder are folders "YYYY Download" with GPX daily files named YYYYMMDD.gpx
# the following are all gpsPhoto options
camError = 0 # seconds. Positive-camera behind. Negative-camera ahead.  Minor error in camera clock
tzoF = 1 # boolean for time zone of camera/photo file. 1 is camera is UTC.
kmlFile = true
maxTimeDiff = 50000 # seconds, default 120, but I changed it 2011.07.26 to allow for pictures taken at night but GPS off. Distance still has to be reasonable, that is the GPS had to be at the same place in the morning as the night before as set by the variable below
# Maybe should write a timediff to file if gt the default.
maxDistance = 25 # meters, default 20
gpxDate = [] # array to store file basenames for the gpx files needed
# end gpsPhoto options and variables

tzoLoc = nil # Time Zone Offset Location from UTC. This is so files are dated according to local picture taken time, not UTC.  
tzoGPSr = tzoLoc # Time Zone Offset GPSr from UTC. What time zone the GPSr thinks it's in as this related to the storing of the daily gpx files. NOT BEING USED, but should redo the gpsYesPashua page to reflect the options
tzoFile = true # true if Camera Setting/Photo files are UTC. False would be if in same time zone as 
gpxFlag = false # for report at end.    NOT BEING USED
### End of initialization

#  Debugging flags. 0 not debugging. 1 for debugging puts
dupDebug = 0 # for working with photos within the same second

####### Below here should not need to be changed.
tempDir = '/tmp/'
fileCount = 0 # all files on card or in folder
# filesRenameCount = 0 # files of interest, not folders, nor .thm, nor .DS_Store
cardCount = 0
cardCountMoved = 0
cardCountCopied = 0
filesMovedCount = 0 # not moved if not on card maybe
photoCoordsFound = 0
photoCoordsNotFound =0
# filesPhotoCount = 0 # I'm going to try not initializing and see if zeroed at start
filesMovieCount = 0
# Time Zone Offset from UTC, tzoLoc = time zone offset
thmCount = 0 # count of thumbnails being deleted.
fileBaseNamePrev = ""
fileExtPrev = ""
fileDatePrev = ""
dupCount = 0
seqLetter = %w(a b c d e f g h i)
gpxFileNo = 0
problemReport = ""
noProblemReport = ""
filePrev = "" # for determining if RAW/JPG pairs
locationFail = []
locFailCount = 0
output = []
# photoArray =[]
geoOnly = "" # no longer in use since version.j
fileSDbasename = "" # if not initialized this variable stays localized in its loop and I need the value outside the loop
whichOneLong= "" # 
## end ititialization

def fileDateUTC(fn) # Except for the first two lines, this seems to be only for Minolta movies, so isn't doing much anymore. In other words if not called much just use the first two active lines
  puts "fn: #{fn}. line ~ 166"
  fileEXIF = MiniExiftool.new(fn)
  fileDateUTC = fileEXIF.dateTimeOriginal # class time
  # puts "\nfileDateUTC: #{fileDateUTC}. fileDateUTC.class: #{fileDateUTC.class}. "
  # the logic here could be FIXed, I think it should be a single NOT
  if fileDateUTC # Minolta mov doesn't have a dateTimeOriginal
    # if fileDateUTC exists we're OK
    # puts "Line 246: fileDateUTC, from .createDate: #{fileDateUTC}. fn: #{fn}. fileDateUTC.class: #{fileDateUTC.class}"
  elsif
    fileDateUTC =  fileEXIF.createDate
    # puts "Line 197: fileDateUTC, from .createDate: #{fileDateUTC}. fn: #{fn}"
    puts "n: #{fn}. dateTimeOriginal doesn't exist for this filef"
  else
    puts "Something went wrong creating a date for a file without a dateTimeOriginal. fn: #{fn}. fileDateUTC"
  end # if fileDateUTC
  return fileDateUTC # got in trouble with not declaring for this method
end # fileDateUTC

def fileAnnotate(fn,fnp,fileDateUTC,tzoLoc)  
  # writing original filename and dateTimeOrig to the photo file.
  fileEXIF = MiniExiftool.new(fnp)
  if fileEXIF.comment.to_s.length < 2 # if exists then don't write. If avoid rewriting, then can eliminate this test
    fileEXIF.comment = fileEXIF.instructions = "Original filename: #{File.basename(fn)} and date: #{fileDateUTC}. Time zone GMT #{tzoLoc}. Zone shown with date is incorrect."
    fileEXIF.save
  end
end # fileAnnotate

def writeTimeDiff(fnp,timediff)
  report = "Note that timediff is #{timediff.to_i/60} minutes."
  fileEXIF = MiniExiftool.new(fnp)
  # fileEXIF.SubjectReference = "#{report}" # In Aperture is Content > IPTC Subject Code. Works but think below is better
  fileEXIF.Title = "#{report}" # In Aperture is Status>Title which is next to Instructions where I put other info.
  fileEXIF.save
end # writeTimeDiff

def pairs(filePrev,fn)
  # returns true if the two files have the same basename w/o ext., i.e. a RAW/JPG pair
  File.basename(filePrev,".*") == File.basename(fn,".*")
end # pairs

def seqNoMeth(fn)
  # grabbing the sequence number from the camera sequencing
  # Need four for Canon, but only three for Minolta. Maybe check
  seqNo = File.basename(fn,".*")[-4,4]
end # seqNoMeth

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
  if fileEXIF.fileType(fn) == "AVI"
    userCamCode = ".lb.c"
  end

  return userCamCode
end # userCamCode

#  As of version s, this shouldn't be needed anymore, EXCEPT when the script is run again on the same files.
def fileExistsAlready(fn,fnpm,dest,fileCount)
  if File.exist?(fnpm)
    puts
    puts "\n#{fileCount}. PROBLEM: #{fnpm} had already been placed in the Latest Download folder, so the file created from #{fn} was placed in the #{dest} folder."
    return true
  end
end # fileExistsAlready

def fnpName(fn, fileBaseName, dest) # called twice from def photo. The test was for sequences which I don't have any more, so shouldn't need a method, jsut the last statement
  if File.basename(fn)[0,2].downcase == 'st'
    # for Canon pano. Putting the sequence number first
    fnp = dest+File.basename(fn)[0,8]+'-'+fileBaseName[0,10]+fileBaseName[-5,5]+File.extname(fn).downcase
  else # all others, i.e., the default
    fnp = dest+fileBaseName+File.extname(fn).downcase
  end
  return fnp
end # fnpName

def photo(fn, fileBaseName, dest, destDup, destOrig, photoHandling,fileCount)
  # fnp: filename of photo in final location
  # fileBaseName is the new base file name, e.g. 2007.07.11-3345.gs.c
  # puts "fnp: #{fnp}"
  # fn is still the filename in the original location, haven't touched that
  # Canon Panoramic, probably want to keep first three letters
  # Canon PhotoStitch.app doesn't care about naming, but only shows about eight characters, so sequencing should be up
  fnp = fnpName(fn, fileBaseName, dest)
  fno = destOrig+File.basename(fn)
  puts = "#{fileCount}. 328 same as imageFile #{fnp} "
  # Need to check if file exists, because if it does the new file won't be copied in (at least I think it's how it works, but finder doesn't show that it happens)
  if fileExistsAlready(fn,fnp,dest,fileCount)
    fnp = fnpName(fn, fileBaseName, destDup)
    puts = "#{fileCount}. #{fnp} is a duplicate and was placed in the Latest Download dups folder."
  end
  # Go ahead and move/copy the files, nothing is being copied over.
  case photoHandling
  when "M" # rename and move the photo
    FileUtils.move(fn, fnp)
  when "C"
    FileUtils.copy(fn,fnp)
  when "R" #rename the photo in place
    File.rename(fn,fnp)
  when "A" #rename and move the photo, and move the original to another folder. Used when photos copied to download folder and then move this original to the already downloaded folder
    FileUtils.copy(fn, fnp) # Rename and copy the photo
    FileUtils.move(fn, fno)# Move the original
  end  # case photoHandling
  return fnp
end # photo


#  Called from gpsInfo and is used to test whether just gpsInfo in place or part of a rename and geolabel and not moving the gpsInfo only ones
def notFoundMove(fn,imageFile,fileBaseName,destNoCoords,fileCount,test)
  fnn = fnpName(fn, fileBaseName, destNoCoords)
  FileUtils.move(imageFile, fnn)
  report = "\n#{fileCount}. \"#{test}\" and photo was not annotated for #{File.basename(imageFile)} by the gpsPhoto.pl and was moved to #{destNoCoords}.  (Original file is #{File.basename(fn)}. Try again to add for reprocessing."
  return report
end # notFoundMove

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

def gpsFileConcatenate(gFiles, gpxFile) # is this called more than once?
  gpsfile = "--gpsfile \""  
  dqs="\" " # dqs double quote space
  gFiles<<(gpsfile+gpxFile+dqs)
end

def gpsInfo(geoOnly, tzoFile, tzoLoc, camError, folderGPX, fileDateUTC, imageFile, fn, fileBaseName, gpsPhotoLoc, maxTimeDiff,maxDistance, fileCount, destNoCoords, problemReport, noProblemReport, photoCoordsFound, gpxFileNo, locFailCount, photoCoordsNotFound, locationFail, geoInfoMethod)
  #puts "gpxDate: #{gpxDate}"
  if tzoFile # true if Camera setting/photo file is UTC.
    geoOffset = camError.to_f
    # puts "Photo files are UTC. geoOffset #{geoOffset/3600}"
  else # false if camera setting/photo file is the same as the local time at the photo location
    geoOffset = -(3600*tzoLoc) + camError.to_f # need to confirm sign of camError portion
    # puts "Photo files are in same time zone as location. geoOffset will be opposite GMT. geoOffset #{geoOffset/3600}"
  end # if tzoFile
  #  --report-distance miles # messes up city with mileage
  #  need quotes around file locations since I have blanks in many of them and they don't pass through without the quotes
  #   puts "\n   folderGPX method. gpxFile: #{gpxFile}. "
  gpxFile = folderGPX +  fileDateUTC.strftime("%Y") + " Download/" + fileDateUTC.strftime("%Y%m%d") + ".gpx"
  # puts "folderGPX method. gpxFile: #{gpxFile}. "
 
  #  Initialize
  gFiles=[] # a collection of daily files (days before and after as needed) for gpsPhoto.pl

  # First, i.e. the day (letting gps photo find if the file exists, see if this works)
  if File.exists?(gpxFile)
    gpsFileConcatenate(gFiles, gpxFile)
  end
  
  gpxFileTEMP = folderGPX +  fileDateUTC.strftime("%Y") + " Download/" + fileDateUTC.strftime("%Y%m%d") + ".TEMP"+ ".gpx" # so can access file for today created by Garmin Log Renaming
  if File.exists?(gpxFileTEMP)
    gFiles = gpsFileConcatenate(gFiles, gpxFileTEMP)
  end
  
  gpxFileI = folderGPX +  fileDateUTC.strftime("%Y") + " Download/" + fileDateUTC.strftime("%Y%m%d") + ".i"+ ".gpx" # so can access file for today created by iPhone using MotionGPX (or other?)
  if File.exists?(gpxFileI)
    gFiles = gpsFileConcatenate(gFiles, gpxFileI)
  end
  
  
  if tzoLoc < 0 # previous or next day. The logic seems backwards, but it gives the right result.
    # need previous day
    diffDate = fileDateUTC - 86400
    # puts "diffDate: #{diffDate}"
    folderPlus = folderGPX +  diffDate.strftime("%Y") + " Download/" + diffDate.strftime("%Y%m%d")
    
    gpxFile = folderPlus + ".gpx"
    if File.exists?(gpxFile)
      gpsFileConcatenate(gFiles, gpxFile)
    end
    
    gpxFileTEMP = folderPlus + ".TEMP"+ ".gpx" # so can access file for previous day created by Garmin Log Renaming
    if File.exists?(gpxFileTEMP)
      gFiles = gpsFileConcatenate(gFiles, gpxFileTEMP)
    end
    
    gpxFileI = folderPlus + ".i"+ ".gpx" # so can access file for previous day created by iPhone using MotionGPX (or other?)
    if File.exists?(gpxFileI)
      gFiles = gpsFileConcatenate(gFiles, gpxFileI)
    end

  else
    # need next day
    diffDate = fileDateUTC + 86400
    # puts "diffDate: #{diffDate}"
    folderPlus =  folderGPX +  diffDate.strftime("%Y") + " Download/" + diffDate.strftime("%Y%m%d")
    
    gpxFile =folderPlus + ".gpx"
    if File.exists?(gpxFile)
      gpsFileConcatenate(gFiles, gpxFile)
    end
    
    gpxFileTEMP = folderPlus + ".TEMP"+ ".gpx" # so can access file for next day created by Garmin Log Renaming
    if File.exists?(gpxFileTEMP)
      gFiles = gpsFileConcatenate(gFiles, gpxFileTEMP)
    end
    
    gpxFileI = folderPlus + ".i"+ ".gpx" # so can access file for next day created by iPhone using MotionGPX (or other?)
    if File.exists?(gpxFileI)
      gFiles = gpsFileConcatenate(gFiles, gpxFileI)
    end
   end # tzoLoc
  # puts "#{fileCount}. gFiles: #{gFiles}"
  # puts "\n#{fileCount}. imageFile: #{imageFile}. "
  if gFiles.to_s.length > 10 # Some way of checking if any of the gpx files found
    perlOutput = `perl \"#{gpsPhotoLoc}\"   --image \"#{imageFile}\" #{gFiles} --timeoffset #{geoOffset} --maxtimediff #{maxTimeDiff} --maxdistance #{maxDistance}  --geoinfo #{geoInfoMethod} --city auto --state guess --country guess  2>&1`
    puts "\n#{fileCount}. perlOutput: \n#{perlOutput}#{fileCount}. End of perlOutput ================" # This didn't seem to be happening with 2>&1 appended? But w/o it, error not captured
    perlOutput =~ /timediff\=([0-9]+)/
    timediff = $1 # class string
    # puts"\n 453 timediff: #{timediff}. timediff.class: #{timediff.class}. "
    if timediff.to_i > 240
      timeDiffReport = ". Note that timediff is #{timediff} seconds. "
      writeTimeDiff(imageFile,timediff)
    else
      timeDiffReport = ""
    end # timediff.to…
    # # Scripts have two "channels" for messages, one for output
    # and one for error messages. After your command, `perlOutput` contains
    # messages from the former. If you append `2>&1` to the command (inside
    # the backticks) it will contain messages from either. If a script doesn't
    # use the error channel it won't make any difference.
    if perlOutput.include?("Found coordinates for 1" )
      test = "Condition: Found coordinates for 1"
      # puts "\n#{fileCount}. Coordinates and location information found and written for #{File.basename(imageFile)} (Original file is #{File.basename(fn)})" # This is accurate
      report = "\n#{fileCount}. Coordinates and location information found for #{File.basename(imageFile)} (Original file is #{File.basename(fn)}). #{test}"
      noProblemReport = noProblemReport + report + timeDiffReport
      photoCoordsFound +=1
    elsif perlOutput.include?"Problem getting geoinfo for point"
      # Note that gpsphoto.pl will not annotate at all with this error, i.e., even though the coordinates are known
      test = "Problem getting geoinfo for point"
      report = notFoundMove(fn,imageFile,fileBaseName,destNoCoords,fileCount,test)
      # puts report
      locationFail << File.basename(imageFile)
      problemReport = problemReport + report + timeDiffReport
      # photoCoordsFound +=1 # not true at the moment, i.e., may have been found but not written
      locFailCount += 1
    elsif perlOutput.include?"Could not find a coordinate"
      test = "Could not find a coordinate"
      # This may only mean that a no gps data is close enough, so nothing to be done unless I want to open up timediff
      # report = notFoundMove(fn,imageFile,fileBaseName,destNoCoords,fileCount,test)
      #  IF TIMEDIFF IS TOO LARGE BUT THE POINTS BEFORE AND AFTER ARE SIMILAR, THEN OK, MAYBE THAT'S THE SAME AS LETTING timediff be large and distance not be too large.
      report = "\n#{fileCount}. timediff: #{timediff}. No coordinates found for #{File.basename(imageFile)} (Original file is #{File.basename(fn)}). Test: #{test}"
      puts report
      problemReport = problemReport + report + timeDiffReport
      photoCoordsNotFound += 1
    else
      # puts "\n#{fileCount}. Everything hunky dory as far as adding coordinates for #{File.basename(imageFile)} (Original file is #{File.basename(fn).downcase})"
    end # if perlOutput
    # puts "\n#{fileCount}. gpsPhoto.pl script output:\n#{perlOutput}"  # perlOutput includes errors and other information, but $! is empty even if   errors. Try $1, null. should also try with the 2>&1 statement, no difference
    if $STDERR.class != NilClass
      report = "\n#{fileCount}. #{fileCount}. $STDERR: #{$STDERR}."
      puts report
      problemReport = problemReport + report
    end
  else
    report = "\n401. #{fileCount}. #{File.basename(imageFile)} didn't have gps coordinates added because #{File.basename(gpxFile)} is missing."
    photoCoordsNotFound += 1
    # puts "** #{report}"
    problemReport = problemReport + report
    gpxFileNo += 1
  end # gFiles.to_s.length > 10
  output = [problemReport, noProblemReport, photoCoordsFound, gpxFileNo, locFailCount, photoCoordsNotFound, locationFail]
end # gpsInfo

def summary(photoHandling,filesMovedCount,fileCount,thmCount,destPhoto,gpxFlag, addGPS2photos, gpxFileNo, photoCoordsFound, photoCoordsNotFound, locFailCount)
  puts"===================================================================="
  puts "Summary of relabeling and geo-coding results:"
  printf "#{filesMovedCount} photos of #{fileCount} files " #FIX move vs rename
  case photoHandling
  when "M"
    printf "were renamed and moved to #{destPhoto} (the originals were deleted)."
  when "C"
    printf "were copied to #{destPhoto} and renamed, and the originals remain untouched."
  end # case
  puts " And #{thmCount} thumbnails were deleted." # (If numbers don't add up, it may be because of an invisible .DS_STORE file.) Removed this because now dealing with ahead of count
  puts
  if addGPS2photos
    if gpxFlag==false
      puts "\n#{gpxFileNo} photos did not have coordinates added because the gpx file was missing.\nCoordinates and location were found for #{photoCoordsFound} photos and \n #{locFailCount} photos were not annotated because of a \"Problem getting geoinfo for point\" failure. \nCoordinates were NOT found for #{photoCoordsNotFound} photos; #{photoCoordsFound+photoCoordsNotFound} photos total."
    end # gpxFlag
  else
    puts "Per request, no geo locating of the photos was performed"
    puts
    # puts "filesRenameCount: #{filesRenameCount}. This isn't useful, but something useful should go here."
  end
end # summary

def copySD(src, srcHD, sdFolderFile, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript, photoHandling, cardCount, cardCountCopied) 
  # some of the above counter variables could be set at the beginning of this script and used locally
  puts "Begin moving or copying photos from SD card. List includes photos skipped. photoHandling: #{photoHandling}\n"
  doAgain = true # name isn't great, now means do it.
  timesThrough = 1 
  fileSDbasename = "" # got an error at puts fileSDbasename
  cardCountMoved = ""
  while doAgain==true # and timesThrough<=2 
    Dir.chdir(src) # needed for glob
    Dir.glob("P*") do |item| 
    # Dir.foreach(src) do |item| 
      cardCount += 1
      # puts "#{cardCount}. item: #{item}. src: #{src}"
      fn = src + item
      fnp = srcHD + "/" + item # using srcHD as the put files here place, might cause problems later
      # get filename and make select later than already downloaded
      fileSDbasename = File.basename(item,".*")
      puts "#{cardCount}. item: #{item}. fileSDbasename: #{fileSDbasename}, fn: #{fn}"
      next if item == '.' or item == '..' or fileSDbasename <= lastPhotoFilename # don't need the first two with Dir.glob, but doesn't slow things down much overall for this script
      # move or copy from card
      case photoHandling
      when "L"
        FileUtils.copy(fn, fnp)
        cardCountCopied += 1
        # cardCountCopied = cardCountCopied + 1 # += gave an error
      when "M"
        FileUtils.move(fn, fnp)
        cardCountMoved = cardCountMoved + 1
      else
        puts "photoHandling not L or M. It's #{photoHandling}"
      end # case
      end # Dir.glob("P*") do |item| 
      # write the number of the last photo copied or moved
      # if fileSDbasename ends in 999, we need to move on to the next folder, and the while should allow another go around.
      doAgain = false
      if fileSDbasename[-3,3]=="999" # and NEXT PAIRED FILE DOES NOT EXIST, then can uncomment the two last lines of this if, but may also have to start the loop over, but it seems to be OK with mid calculation change.
          nextFolderNum = fileSDbasename[-7,3].to_i + 1 # getting first three digits of filename since that is also part of the folder name
          nextFolderName = nextFolderNum.to_s + "_PANA"
          begin
            # puts "thisScript + sdFolderFile #{thisScript + sdFolderFile}"
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
      timesThrough += 1
      puts "491. timesThrough: #{timesThrough}. doAgain: #{doAgain}"
  end # if doAgain…
  begin
      fileNow = File.open(thisScript + lastPhotoReadTextFile, "w") # must use explicit path, otherwise will use wherever we are are on the SD card
      fileNow.puts fileSDbasename
      fileNow.close
      puts "\n494. The last file processed. fileSDbasename, #{fileSDbasename}, written to  #{fileNow}."
    rescue IOError => e
      puts "Something went wrong. Could not write last photo read (#{fileSDbasename}) to #{fileNow}"
    # ensure
    #   fileNow.close unless fileNow == nil
    end # begin
    puts "\n502. Of the #{cardCount} photos on the SD card, #{cardCountCopied} were copied and #{cardCountMoved} were moved." # Could get rid of the and with an if somewhere since only copying or moving is done.
    puts "503. Done moving or copying photos from SD card. src switched from card to folder holder moved or copied photos: #{src}"  
end # copySD


## end  methods

#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_
#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_

## The "program" #################
puts "Fine naming and moving started: #{Time.now}" # for trial runs

# get current folder for photos on Greg's SD card, new folder every 1000 photos
begin
  file = File.new(sdFolderFile, "r")
  sdFolder = file.gets
  file.close
rescue Exception => err
  puts "Exception: #{err}. Could not read which folder is current on the SD card from #{sdFolderFile}"
end
srcSD = srcSDfolder + sdFolder
# puts "Current folder for photos on SD card (srcSD): #{srcSD}"
whereFrom = whichLoc() # from dialog window SAY WHAT. This is pulling in first Pashua window, SDorHD.rb which has been required
whichOne = whereFrom["whichDrive"][0].chr # only using the first character
if whichOne=="S"
  whichOne = "SD"
  src = srcSD
  whichOneLong = " a plugged in SD card."
else
  whichOne = "HD"
  src = srcHD
  whichOneLong = whichOneLong + " a folder on a hard drive."
end # whichOne=="S"
puts "Will process original photos from #{src}, #{whichOneLong}."

if whichOne=="SD" # otherwise it's HD, probably should be case to be cleaner coding
  # read in last filename copied from card previously
  begin
    file = File.new(thisScript + lastPhotoReadTextFile, "r")
    lastPhotoFilename = file.gets # apparently grabbing a return. maybe not the best reading method.
    puts "540. lastPhotoFilename: #{lastPhotoFilename}. Read from #{lastPhotoReadTextFile}. Value can be changed by user, so this may not be the final value."
    file.close
  rescue Exception => err
    puts "Exception: #{err}. Not critical as value can be entered manually by user."
  end
  prefsPhoto = pPashua(src,lastPhotoFilename,destPhoto,destOrig,photoHandling,addGPS2photos) # is this only sending values in? 
  # to get a value use prefsPhoto("theNameInFileNamingEtcPashue.rb"), nothing to do with the name above
  # puts "Prefs as set by pPashua"
  # prefsPhoto.each {|key,value| puts "#{key}:       #{value}"}
  src = prefsPhoto["srcSelect"]  + "/"
  lastPhotoFilename = prefsPhoto["lastPhoto"]
  destPhoto = prefsPhoto["destPhotoP"]
  destOrig  = prefsPhoto["destOrig"]
  photoHandling = prefsPhoto["photoHandle"][0].chr # only using the first character 
else # whichOne=="HD"
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


# #  Changing from 1 and 0 to true and false
# case prefsPhoto["geoLoc"]
# when "1" : addGPS2photos = true
# when "0" : addGPS2photos = false
# else puts "We've got a problem determining addGPS2photos"
# end

case prefsPhoto["geoOnly"]
when "1" then geoOnly = true
when "0" then geoOnly = false
else puts "We've got a problem determining geoOnly"
end

# case prefsPhoto["tzoF"]
# when "1" : tzoFile = true
# when "0" : tzoFile = false
# else puts "We've got a problem determining some time zone stuff"
# end

# tzoLoc = prefsPhoto["tzcP"]
# puts "addGPS2photos: #{addGPS2photos}"

# prefs for geo locating. 
if addGPS2photos
  # Uses gpsYesPashua
  prefsGPX = geoGUI(gpsPhotoLoc,folderGPX,tzoLoc,tzoGPSr,camError,maxTimeDiff,maxDistance,kmlFile)
  # prefsGPX = geoGUI(src,destPhoto,gpsPhotoLoc,srcGPX,tzoLoc,tzoGPSr,camError,maxTimeDiff,maxDistance,kmlFile) # src and destPhoto here weren't really needed2011.03.13
  # puts
  #puts "Prefs as set by geoGUI"
  # prefsGPX.each {|key,value| puts "#{key}:       #{value}"}
  # src = prefsGPX["srcSelect"] # not used after 2011.03.15. 
  folderGPX = prefsGPX["gpxFolder"]  +'/' # fix to add trailing / needed since add file name.
  maxTimeDiff = prefsGPX["maxTimeDiffP"].to_i
  maxDistance = prefsGPX["maxDistanceP"].to_i
  camError = prefsGPX["toP"]
  case prefsGPX["kmlYN"]
  when "1" then kmlFile = true
  when "0" then kmlFile = false
  end
  tzoLoc = prefsGPX["tzcP"].to_f # needed or get error timeChange. Took the hint from the .to_f for camError
end # if addGPSphotos

# destAnnot = destPhoto # this should be eliminated or fixed, i.e., make them the same FIX DONE 2011.07.07
# puts "scr:       /Volumes/NO NAME/DCIM/113_PANA/  This works if manually entered"
puts "src:       #{src}"
# puts "destAnnot: #{destAnnot}"
puts "destOrig:  #{destOrig}"
puts "destPhoto: #{destPhoto}\n"
# puts "destDup:   #{destDup}"
# puts "folderGPXfolderGPX: #{folderGPX}"
puts "folderGPX: #{folderGPX}\n"
puts "lastPhotoFilename: #{lastPhotoFilename} for copying/moving from SD card. This is the starting point and may have been changed by user."
if tzoFile # true if Camera setting/photo file is UTC. # Should make this more robust, i.e., confirm more logic
  puts "time offsets: #{camError} seconds camera error, #{maxTimeDiff} seconds (#{maxTimeDiff/60} minutes, #{maxTimeDiff/3600} hours) max. time difference between points, and photos were taken in time zone #{tzoLoc} GMT, but they are time stamped in UTC.\n#{maxDistance}m max. distance between points"
else
  puts "time offsets: #{camError} seconds camera error, and photos were taken in time zone #{tzoLoc} GMT, and are time stamped in that time zone"
end # tzoFile


#puts "prefsPhoto[\"srcSelect\"]: #{prefsPhoto["srcSelect"]}
#puts "#{Find.find(src).count} are being considered."
puts
puts "Intialization and complete. File renaming and copying/moving beginning..."

#  If working from SD card, copy or move files to " Drag Photos HERE Drag Photos HERE" folder, then will process from there.
if whichOne == "SD"
  copySD(src, srcHD, sdFolderFile, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript, photoHandling, cardCount,cardCountCopied)
end # if SD

src = srcHD # switching since next part works from copied files on hard drive. No longer need reference to SD card. COULD OPTION TO DELETE RATHER THAN MOVE TO already imported. Might not be needed if src stays local to copySD

photoHandling = "A" # photoHandling was referring to how to handle files on card, now switching to how to handle the files in the DRAG photos here folder. Could add back options to move
puts "\n 649. Photos will now be copied and renamed. \nUsing #{geoInfoMethod} as a source, GPS information will be added to photos.........."
#  Now working from hard drive whether or not originals were copied by hand or the program.
if !File.exists?(src) # 1. didn't think this should be necessary, but weird errors if not. Need to put in better fault tolerance FIX, but runs once
  puts "Photo directory is missing. src: #{src}"
  #  For only adding geo coordinates and information. No renaming
else
  Dir.chdir(thisScript) # otherwise didn't know where it was to find folderGPX since used a chdir elsewhere in the script
  Dir.foreach(src) do |item| 
    next if item == '.' or item == '..' or item == '.DS_Store' # If this works remove from about ten lines down
    fn = src + item
    if geoOnly==true # else covers the normal situation
      # for photos being georeferenced (in place?) without renaming
      # set up variables that would have defined later for a file being renamed.
      imageFile = fn # in this case fn (original name) and imageFile (new name) are the same since no renaming going on
      fileDateUTC = fileDateUTC(fn)
      fileCount += 1
      output = gpsInfo(geoOnly, tzoFile, tzoLoc, camError, folderGPX, fileDateUTC, imageFile, fn, fileBaseName="", gpsPhotoLoc, maxTimeDiff,maxDistance, fileCount, destNoCoords, problemReport, noProblemReport, photoCoordsFound, gpxFileNo, locFailCount, photoCoordsNotFound, locationFail, geoInfoMethod)
      problemReport = output[0]
      noProblemReport = output[1]
      photoCoordsFound = output[2]
      gpxFileNo = output[3]
      locFailCount = output[4]
      photoCoordsNotFound = output[5]
      locationFail = output[6]
    else # For normal situation where photos are renamed, moved, and geo coordinates
      # 
      # puts "\n709. #{fileCount}. fn: #{fn}"
      if File.file?(fn) # worked for Minolta, but didn't work when .DS_Store was found
        fileCount += 1
        # Delete thm before going any further. This is for Minolta and Canon
        if ['.thm'].include?(File.extname(fn).downcase)
          File.delete(fn)
          thmCount += 1
        end # ['.thm'].include?(File.extname(fn).downcase)
        if (!['.thm'].include?(File.extname(fn).downcase))  and (File.basename(fn) != ".DS_Store")  # 4. don't process .thm or other cruft. SHOULDN'T THIS BE AN 'OR' SHOULDN'T BE NEEDED AS BOTH OF THESE HAVE BEEN DEALT WITH EARLIER
          # Determine the time zone where the photo was taken
          fileDateUTC = fileDateUTC(fn)
          tzoLoc = timeZone(fileDateUTC, timeZonesFile)
          # puts "721. fileDateUTC: #{fileDateUTC}.  tzoLoc: #{tzoLoc}"
          # catching corrupt files (mostly from file recovery, but who knows). Hard wired but could generalize
          begin
            # camError is a string
            if tzoFile # true if Camera setting/photo file is UTC.
              timeChange = (3600*tzoLoc) + camError.to_f
              # puts "timeChange: #{timeChange} seconds"
            else # false if camera setting/photo file is the same as the local time at the photo location
              timeChange = camError.to_f
            end
            # puts "731. fileDateUTC: #{fileDateUTC}"
            fileDate = fileDateUTC + timeChange
            gpxDate = fileDateUTC.strftime("%Y%m%d")+ ".gpx"
          rescue # possible this isn't needed. May have been here because the lack of .to_f caused for tzoLoc
            puts "Error getting date for #{fn} and file was moved out of the way"
            # FIX need to include the folder below in set up or create a way out to create the folder
            FileUtils.move(fn,"/Volumes/Knobby Aperture II/_Download folder/Latest Download Problems")
            next
          end # begin-rescue

          # Check for photos taken in the same second. Works sometimes. Have to watch for when it doesn't
          pairs = pairs(filePrev,fn) # checking if RAW/JPG pairs returns true or false.
          if dupDebug==1 && pairs
            puts "\nWe have a RAW/JPG pair: #{File.basename(filePrev)} and #{File.basename(fn)}"
          end
          filePrev = fn
          # Working out if files at the same time and also if paired (a JPG/RAW of the same shot)
          oneBack = fileDateUTC == fileDatePrev # true if previous file at the same time
          puts "\n #{fileCount}. oneBack: #{oneBack}. pairs: #{pairs}" if dupDebug==1
          # Determine dupCount, i.e., 0 if not in same second, otherwise the number of the sequence for the same time
          if oneBack
            if !pairs # if second of pair depCount doesn't change
              dupCount += 1
            end
          else
            dupCount = 0 # normal situation, a photo not in the same second
          end # oneBack
          fileDatePrev = fileDateUTC
          # Now the fileBaseName. Simple if not in the same second, otherwise an added sequence number
          if dupCount == 0
            fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S")  + userCamCode(fn)
          else
            puts "\n#{fileCount}. dupCount: #{dupCount}. seqLetter[dupCount]: #{seqLetter[dupCount]}"  if dupDebug==1
            fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  seqLetter[dupCount] + userCamCode(fn)
          end # dupCount

          fileBaseNamePrev = fileBaseName
         
          # makes double sure not doing .thm or DS_Store although they should already be screened out
          case (File.extname(fn).downcase) # movie or photo
          when '.jpe','.jpg','.jpeg','.mrw','.mov','.avi','.rw2'
            # File renaming and/or moving happens here
            # puts "\n#{fileCount}. fn: #{fn}. fileBaseName: #{fileBaseName}. destPhoto: #{destPhoto}. destDup: #{destDup}. destOrig: #{destOrig}. photoHandling: #{photoHandling}"
            imageFile = photo(fn, fileBaseName, destPhoto, destDup, destOrig, photoHandling,fileCount)
            # puts "fn: #{fn}. imageFile: #{imageFile}. fileDateUTC: #{fileDateUTC}. tzoLoc:#{tzoLoc}"
            fileAnnotate(fn,imageFile,fileDateUTC,tzoLoc) # adds original file name and date to EXIF.comments which I think show up as instructions in Aperture
            filesMovedCount += 1 # this needs to be FIXed to break out the various final dispensations
          end # case
          if addGPS2photos
            # puts "\n#{fileCount}.fileDateUTC: #{fileDateUTC}. Time Zone showing is computer time zone. Need to fix someday."
            output = gpsInfo(geoOnly, tzoFile, tzoLoc, camError, folderGPX, fileDateUTC, imageFile, fn, fileBaseName, gpsPhotoLoc, maxTimeDiff,maxDistance, fileCount, destNoCoords, problemReport, noProblemReport, photoCoordsFound, gpxFileNo, locFailCount, photoCoordsNotFound, locationFail, geoInfoMethod)
            problemReport = output[0]
            noProblemReport = output[1]
            photoCoordsFound = output[2]
            gpxFileNo = output[3]
            locFailCount = output[4]
            photoCoordsNotFound = output[5]
            locationFail = output[6]
            # shouldn't there be an else for not adding gps info?
          end
        end # 4. if thm, etc.
      end # 3. if File
    end # 2.5 geoOnly==true
  end # 2. Find
end # 1. if !File.exists?(src) checking for photo folder
puts
problemReport = problemReport +"\n\nLocation fail array (for working on this. At the moment, no coordinates and location fail are the same. So don't need this unless find the difference. Need the array, but content needs to change): #{locationFail}" if locFailCount!= 0 # don't need once deal with this

summary(photoHandling,filesMovedCount,fileCount,thmCount,destPhoto,gpxFlag,addGPS2photos,gpxFileNo,photoCoordsFound,photoCoordsNotFound,locFailCount)
puts "\nProblem Report Details:\n#{problemReport}"  if problemReport != "" # This wasn't working right
puts "\nSuccess Report Details:\n#{noProblemReport}"
puts "============================================================="
# puts "locationFail array: #{locationFail}=======
