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
require 'geonames'

require_relative 'lib/SDorHD'
require_relative 'lib/Photo_Naming_Pashua-SD2'
require_relative 'lib/Photo_Naming_Pashua–HD2'
require_relative 'lib/gpsYesPashua'

thisScript = File.dirname(__FILE__) +"/" # needed because the Pashua script calling a file seemed to need the directory. 
srcSDfolder = "/Volumes/Untitled/DCIM/" # SD folder. Panasonic and probably Canon
# srcSDfolder = "/Volumes/Untitled/DCIM/" # SD folder. Maybe temp for an unformated card? 2014.06.10
srcHD = "/Volumes/Knobby Aperture Seagate/_Download folder/ Drag Photos HERE/"  # Photos copied from original location such as camera or sent by others
# srcHD = "/Users/gscar/Pictures/_Photo Processing Folders/Download folder/" # for laptop use. NEED TO SET UP TRAVEL OPTION
sdFolderFile = thisScript + "currentData/SDfolder.txt" # shouldn't need full path

# # Appropriate folders on Knobby Aperture NOT USING THIS AS MAIN PLACE ANYMORE
# downloadsFolders = "/Volumes/Knobby Aperture Seagate/_Download folder/"
# destPhoto = downloadsFolders + "Latest Download/" #  These are relabeled and GPSed files.
# destOrig  = downloadsFolders + "_already imported/" # folder to move originals to if not done in

# Appropriate temporary folders on laptop
laptopLocation = "/Users/gscar/Pictures/_Photo Processing Folders/"
laptopDownloadsFolder = laptopLocation + "Download folder/"
laptopDestination = laptopLocation + "Processed photos to be imported to Aperture/"
laptopDestOrig = laptopLocation + "Originals to archive/"

# Folders on portable drive: Knobby Aperture Seagate
downloadsFolders = "/Volumes/Knobby Aperture Seagate/_Download folder/"
destPhoto = downloadsFolders + "Latest Download/" #  These are relabeled and GPSed files.
destOrig  = downloadsFolders + "_already imported/" # folder to move originals to if not done in 

lastPhotoReadTextFile = thisScript + "currentData/lastPhotoRead.txt"
geoInfoMethod = "wikipedia" # for gpsPhoto to select georeferencing source. wikipedia—most general and osm—maybe better for cities
timeZonesFile = "/Users/gscar/Dropbox/scriptsEtc/Greg camera time zones.yml"
timeZones = YAML.load(File.read(timeZonesFile)) # read in that file now and get it over with
# gpsPhotoPerl = "lib/gpsPhoto.pl" # Perl script that puts gps locations into the photos. SEEMS TO WORK WITHOUT ./lib
# gpsPhotoPerl = "/Users/gscar/Documents/Ruby/Photo handling/lib/gpsPhoto.pl"
gpsPhotoPerl = thisScript + "/lib/gpsPhoto.pl"
folderGPX = "/Users/gscar/Dropbox/   GPX daily logs/2014 Massaged/" # Could make it smarter, so it knows which year it is. Massaged contains gpx files from all locations whereas Downloads doesn't 
geoNamesUser    = "geonames@web.knobby.ws"

# puts "RUBY_DESCRIPTION: #{RUBY_DESCRIPTION}\n\n" # probably isn't always accurate. Just look in the purple on the window

def timeStamp(timeNowWas)  
  seconds = Time.now-timeNowWas
  minutes = seconds/60
  if minutes < 2
    report = "#{seconds.to_i} seconds"
  else
    report = "#{minutes.to_i} minutes"
  end   
  puts "-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -   #{report}. #{Time.now.strftime("%I:%M:%S %p")}   -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  "
  Time.now
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
  puts "\n81. Copying photos from an SD card"
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
          # fileNow = File.open(thisScript + sdFolderFile, "w") # Was 2014.02.28 How could this have worked?
          fileNow = File.open(sdFolderFile, "w")
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
    puts "\n127. Of the #{cardCount} photos on the SD card, #{cardCountCopied} were copied" # Could get rid of the and with an if somewhere since only copying or moving is done.
    # puts "125. Done copying photos from SD card. src switched from card to folder holder moved or copied photos: #{src}"  
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
  puts "\n137. Copy photos to the final destination (Latest Download) where the renaming will be done and the originals moved to an archive (already imported folder)"
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
    FileUtils.copy(fn, fnp) # making a copy in the Latest Downloads folder for further action
    if File.exists?(fnf)  # moving the original to _already imported, but not writing over existing files
      fnf = uniqueFileName(fnf)
      FileUtils.move(fn, fnf)
      puts "\n182. A file already existed with this name so it was changed to fnf: #{fnf}"
    else # no copies, so move
      FileUtils.move(fn, fnf)
    end
    itemPrev = item
    photoFinalCount += 1
  end # Dir.foreach
  # puts "\n158. #{photoFinalCount} photos have been moved and are ready for renaming and gpsing. #{delCount-1} duplicate jpg were not
  if delCount > 1
    comment = ". #{delCount-1} duplicate jpg were not moved."
  else
    comment = ""
  end
  puts "\n212. #{photoFinalCount} photos have been moved and are ready for renaming and gpsing#{comment}"
end # copyAndMove: copy to the final destination where the renaming will be done and the original moved to an archive (already imported folder)

def userCamCode(fn)
  fileEXIF = MiniExiftool.new(fn)
  ## not very well thought out and the order of the tests matters
  case fileEXIF.model
  when "DMC-G2"
    userCamCode = ".gs.L" # gs for photographer. L for Panasonic *L*umix DMC-G2
  when "DMC-GX7"
    userCamCode = ".gs.P" # gs for photographer. P for Panasonic Lumix DMC-GX7
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
  # fileEXIF = MiniExiftool.new(fn) # done already
  # SEEMS SLOPPY THAT I'M OPENING THE FILE ELSEWHERE AND SAVING IT HERE
  if fileEXIF.comment.to_s.length < 2 # if exists then don't write. If avoid rewriting, then can eliminate this test
     fileEXIF.instructions = "#{fileDateUTCstr} UTC. Time zone of photo is GMT #{tzoLoc}"
    # fileEXIF.comment = "Capture date: #{fileDateUTCstr} UTC. Time zone of photo is GMT #{tzoLoc}. Comment field" # Doesn't show up in Aperture
    # fileEXIF.source = fileEXIF.title = "#{File.basename(fn)} original filename" # Source OK, but Title seemed a bit better
    fileEXIF.title = "#{File.basename(fn)}"
    fileEXIF.TimeZoneOffset = tzoLoc
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
    # puts "\n217.. #{i}. fileDateUTC: #{fileDateUTC}. theTime: #{theTime}. fileDateUTC.class: #{theTime.class}. fileDateUTC.class: #{theTime.class}"
    # puts "Note that these dates are supposed to be UTC, but are getting my local time zone attached."
    if fileDateUTC > theTime
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
    puts "289. item: |#{item}|. item != \"Icon \": #{item != "Icon "}. item != \'.DS_Store\': #{item != '.DS_Store'}."
    next if item == '.DS_Store' 
    next if item == '.' 
    next if item == '..' 
    next if item == "Icon "
    puts "294. item: #{item}. This item will be processed renamed.hj"
    fn = src + item
       # puts "\n709. #{fileCount}. fn: #{fn}"
    puts "295.. File.file?(fn): #{File.file?(fn)}. fn: #{fn}"
    if File.file?(fn) # 
      # Determine the time and time zone where the photo was taken
      puts "298.. fn: #{fn}. File.ftype(fn): #{File.ftype(fn)}"
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
  # puts "\n286.. gpsPhotoPerl.shellescape: #{gpsPhotoPerl.shellescape}. but can't figure out how to make this work. So done manually"
  # puts "\n287.. `perl \"#{gpsPhotoPerl.shellescape}\" --dir #{destPhoto.shellescape} --gpsdir #{folderGPX.shellescape} --timeoffset 0 --maxtimediff 50000 2>&1`"
  puts "\n288. Finding all gps points from all the gpx files using gpsPhoto.pl. This may take a while"
  perlOutput = `perl '/Users/gscar/Documents/Ruby/Photo\ handling/lib/gpsPhoto.pl' --dir '/Volumes/Knobby\ Aperture\ II/_Download\ folder/Latest\ Download/' --gpsdir '/Users/gscar/Dropbox/\ \ \ GPX\ daily\ logs/2014\ Massaged/' --timeoffset 0 --maxtimediff 50000`
  # perlOutput = "`perl #{gpsPhotoPerl.shellescape} --dir #{destPhoto.shellescape} --gpsdir #{folderGPX.shellescape} --timeoffset 0 --maxtimediff 50000 2>&1`"
      
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

def addLocation(src, geoNamesUser)
  # read coords and add a hierarchy of choices for location information. Look at GPS Log Renaming for what works.
    countTotal = 0 
    countLoc = 0
    Dir.foreach(src) do |item| 
    next if item != '.' or item != '..' or item != '.DS_Store' or item != 'Icon ' # See notes in rename method
    fn = src + item
    if File.file?(fn) 
      countTotal += 1
      fileEXIF = MiniExiftool.new(fn)
      # Get lat and lon from photo file
      puts "311.. No gps information for #{item}. #{fileEXIF.title}" if fileEXIF.specialinstructions == nil
      next if fileEXIF.specialinstructions == nil # can I combine this step and the one above into one step or if statement? 
      gps = fileEXIF.specialinstructions.split(", ") # or some way of getting lat and lon. This is a good start. Look at input form needed
      lat = gps[0][4,11] # Capture long numbers like -123.123456, but short ones aren't that long, but nothing is there
      lon = gps[1][4,11].split(" ")[0] # needs to 11 long to capture when -xxx.xxxxxx, but then can capture the - when it's xx.xxxxxx. Then grab whats between the first two spaces. Still need the 4,11 because there seems to be a space at the beginning if leave out [4,11]
      countLoc += 1 # gives and error here or at the end.
      # puts "\n321.. #{countTotal}. Use geonames to  Determine city, state, country, location. #{item}"
      api = GeoNames.new(username: geoNamesUser) 

      # Determine country 
      begin
        # doesn't work for Istanbul, works for Croatia
        ccountryCodeGeo = api.country_code(lat: lat, lng: lon) # doesn't work in Turkey
        countryCode  = countryCodeGeo['countryCode'] 
      rescue
        begin
          countryCodeGeo = api.find_nearby_place_name(lat: lat, lng: lon).first # works for Turkey
          countryCode  = countryCodeGeo['countryCode'] 
        rescue SocketError # SocketError: getaddrinfo: nodename nor servname provided, or not known. NOT SURE WHAT THE FAILURE IS HERE. WILL SEE IF IT HAPPENS AGAIN
          puts " 366. Failing for api.find_nearby_place_name(lat: lat, lng: lon).first #{lat} #{lon} \nfor #{src}\n"
          $stderr.print  $! # Thomas p. 108
        end
      end
       
      # puts "331.. countryCode:  #{countryCode}"
      country = countryCodeGeo['countryName'] # works with both country_code  and find_nearby_place_name above
      # puts "333.. country:      #{country}"

      # Determine city, state, location
      if countryCode == "US"
        begin # state
          postalCodes = api.find_nearby_postal_codes(lat: lat, lng: lon, maxRows: 1) # this comes up blank for some locations in the US eg P1230119, so did find_nearest_address 
          state = postalCodes.first['adminName1']
          # puts "46.. api.find_nearby_postal_codes worked"
        rescue 
          state = api.country_subdivision(lat: lat, lng: lon, maxRows: 1)['adminName1']
          # puts "49. api.find_nearby_postal_codes failed, so used  api.country_subdivision"
        end
        # puts "335.. state:        #{state}"
        
        begin  # city, location
          neigh = api.neighbourhood(lat: lat, lng: lon) # errors outside the US and at other time
          city =  neigh['city']
          # puts "339.. city:         #{city}"
          location = neigh['name']
          # puts "386.. location:     #{location}"
        rescue # could use api.find_nearby_postal_codes for some of this
          # puts "344.  api.neighbourhood failed for #{lat} #{lon}"
          
          begin # within a rescue
            city = postalCodes.first['placeName'] # breaking for some points, but is it better than replacement? If so add another rescue
            # puts "355.. city (rescue): #{city}"
            findNearbyPlaceName = api.find_nearby_place_name(lat: lat, lng: lon)
            location = findNearbyPlaceName.first['toponymName']
            # puts "358.. location (rescue): #{location}"      
          rescue # probably end up here for a remote place, so wikipedia may be the best
            # puts "360.. find_nearby_postal_codes failed for city, so use Wikipedia to find a location"
            city = ""
            distance = api.find_nearby_wikipedia(lat: lat, lng: lon, maxRows: 1)['geonames'].first['distance']
            location = api.find_nearby_wikipedia(lat: lat, lng: lon, maxRows: 1)['geonames'].first['title']
            puts "363.. location:     #{location}. distance: #{distance}" # may need to screen as for outside US
          end # of within a rescue
  
        end # begin rescue outer
        
      else # outside US
        findNearbyPostalCodes = api.find_nearby_postal_codes(lat: lat, lng: lon, maxRows: 1).first
        state = findNearbyPostalCodes['adminName1']
        puts "353.. state (outside US): #{state}"
        # city = findNearbyPostalCodes['placeName'] # close to city, but misses Dubrovnik and Zagreb
        city = api.find_nearby_place_name(lat: lat, lng: lon, maxRows: 1).first['toponymName'] # name or adminName1 could work too
        puts "355.. city (outside US):  #{city}"
        # puts city =  api.find_nearby_wikipedia(lat: lat, lng: lon)["geonames"].first["title"] # the third item is a city, maybe could regex wikipedia, but doubt it's consistent enough to work 
        location = api.find_nearby_wikipedia(lat: lat, lng: lon, maxRows: 1)['geonames'].first['title'] 
        distance = api.find_nearby_wikipedia(lat: lat, lng: lon, maxRows: 1)['geonames'].first['distance'].to_f
        puts "382.. location:     #{location}. distance: #{distance}. If distance > 0.3km location not used"
        location = "" if distance < 0.3      
      end # if countryCode
      location = "" if city == location # cases where they where the same (Myers Flat, Callahan and Etna). Could try to find a location with some other find, maybe Wikipedia, but would want a distance check
      # puts "355.. Use MiniExiftool to write location info to photo files\n" # Have already set fileEXIF
      fileEXIF.CountryCode = countryCode  # Aperture: IPTC: Country-PrimaryLocationCode
      fileEXIF.country = country  # Aperture: IPTC: Country-Primary Location Name
      fileEXIF.state = state # Aperture: IPTC: Province-State (XMP: Stqte)
      fileEXIF.city = city # Aperture: IPTC: City
      fileEXIF.location = location # Aperture: IPTC: Sub-location
      fileEXIF.save
      # Now have lat and long and now get some location names
    end    
  end 
  puts "\n398. Location information found for #{countLoc} of #{countTotal} photos processed" 
end

def writeTimeDiff(perlOutput)
  perlOutput.each_line do |line|
    if line =~ /timediff=/
      fn = $`.split(",")[0]
      timeDiff = $'.split(" ")[0]
      # puts "\n439.. #{fn} timeDiff: #{timeDiff}"
      fileEXIF = MiniExiftool.new(fn)
      fileEXIF.usageterms = "#{timeDiff} seconds from nearest GPS point"
      fileEXIF.save
    end
  end
end #  Write timeDiff to the photo files

## The "program" #################
timeNowWas = timeStamp(Time.now) # this first use of timeStamp is different
puts "Are the gps logs up to date?"
puts "Fine naming and moving started  . . . . . . . . . . . . " # for trial runs  #{timeNowWas}
srcSD = srcSDfolder + sdFolder(sdFolderFile)

if !File.exists?(downloadsFolders) # if KnobbyAperture isn't mounted use folders on laptop
  puts "487. #{downloadsFolders} isn't mounted, so will use local folders to process"
  downloadsFolders = laptopDownloadsFolder
  destPhoto = laptopDestination
  destOrig  = laptopDestOrig
end

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

puts "\n520. Intialization complete. File renaming and copying/moving beginning. Time below is responding to options requests via Pashua"

timeNowWas = timeStamp(Time.now) # Initial time stamp is different. Had this off and no time for start when copying from SD card

#  If working from SD card, copy or move files to " Drag Photos HERE Drag Photos HERE" folder, then will process from there.
copySD(src, srcHD, sdFolderFile, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) if whichOne == "SD"
#  Note that file creation date is the time of copying. May want to fix this. Maybe a mv is a copy and move which is sort of a recreation. 

timeNowWas = timeStamp(timeNowWas)
puts "\n452. Photos will now be moved and renamed."

# puts "First will copy to the final destination where the renaming will be done and the original moved to an archive (already imported folder)"
#  Only copy jpg to destPhoto if there is not a corresponding raw, but keep all taken files. With Panasonic JPG comes before RW2
copyAndMove(srcHD,destPhoto,destOrig)

timeNowWas = timeStamp(timeNowWas)

puts "\n532. Rename the photo files with date and an ID for the camera or photographer"
rename(destPhoto, timeZones)

timeNowWas = timeStamp(timeNowWas)

puts "\n435. Using perl script to add gps coordinates. Will take a while as all the gps files for the year will be processed and then all the photos."


# Add GPS coordinates. Will add location later using some options depending on which country since different databases are relevant.
perlOutput = addCoordinates(destPhoto, folderGPX, gpsPhotoPerl)

timeNowWas = timeStamp(timeNowWas)

# Write timeDiff to the photo files
puts "\n520. Write timeDiff to the photo files"
writeTimeDiff(perlOutput)

timeNowWas = timeStamp(timeNowWas)
# Parce perlOutput and add maxTimeDiff info to photo files

# Add location information to photo file
addLocation(destPhoto, geoNamesUser)
puts "\n504.-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -All done"
timeNowWas = timeStamp(timeNowWas)