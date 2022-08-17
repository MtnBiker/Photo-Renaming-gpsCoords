#!/usr/bin/env ruby
# mini_exiftool couldn't be found. Was a problem with  TM_RUBY, GEM_PATH, AND GEM_HOME not matching the what TextMate is using. TM does not use .ruby_version

# Using GitHub so can use on MBP (laptop)

# Look at https://github.com/txus/kleisli for getting location information from geonames.
# Look at speeding up with https://github.com/tonytonyjan/exif for rename and annotate which is rather slow. 8 min. for 326 photos
# 2019/05/10 installed libexif and tried to use. Got error File not readable or no EXIF data in file. (Exif::NotReadable). Issue still open after two years at tonytonyjan
# puts "Ruby v#{RUBY_VERSION}p#{RUBY_PATCHLEVEL} as reported by Ruby\nAnd as reported by \`system ('gem env')\`:" # A Ruby constant
# system ('gem env') # for debugging problem with gem not loading https://stackoverflow.com/questions/53202164/textmate-chruby-and-ruby-gems

# puts "\n10. Gem.path: #{Gem.path}"
# puts "\ngem list:" # Can't figure out how to do this in one line.
# system ('gem list') # for debugging problem with mini_exiftool not loading

require 'fileutils'
include FileUtils
require 'find'
require 'yaml'
require "time"
# require 'shellwords'
require 'irb' # binding.irb where error checking is desired
require 'mini_exiftool'
# require 'exif' # added later. A partial implementation of ExifTool, but faster than mini_exiftool. Commented out since doesn't work with Panasonic Raw

# require 'geonames' # Brought into the script because was getting loading errors
# The these first three requires are for geonames and then the class
require 'json'
require 'open-uri'
require 'addressable/template' #  gem install addressable

require_relative 'lib/gpsYesPashua'
require_relative 'lib/LatestDownloadsFolderEmpty_Pashua'
require_relative 'lib/Photo_Naming_Pashua-SD2'
require_relative 'lib/Photo_Naming_Pashua–HD2'
require_relative 'lib/SDorHD'
require_relative 'lib/renamePashua' # Dialog for renaming without moving
require_relative 'lib/gpsCoordsPashua' # Dialog for adding GPS coordinates without moving
require_relative 'lib/gpsAddLocationPashua' # Dialog for adding location information based GPS coordinates in file EXIF without moving

HOME = "/Users/gscar/"
thisScript = File.dirname(__FILE__) +"/" # needed because the Pashua script calling a file seemed to need the directory. 

def lineNum() # Had to move this to above the first call or it didn't work. Didn't think that was necessary
  caller_infos = caller.first.split(":")
  # Note caller_infos[0] is file name
  caller_infos[1]
end # line numbers of this file, useful for debugging and logging info to progress screen

photosArray = [] # can create initially, but I don't know how to add other "fields" to a file already on the list. I'll be better off with an indexed data base. I suppose could delete the existing item for that index and then put in revised. Not using this, but maybe some day
sdCard      = "/Volumes/LUMIX/"
puts "#{lineNum}. Could be a problem with differently named SD cards: #{sdCard}. If the name is different, change #{lineNum.to_i - 1}" # In 2022, I got creative and named the LUMIX cards with a suffix in numerical order.
lastPhotoReadTextFile = sdCard + "/DCIM/" # SD folder alternate since both this and one below occur
sdCardAlt   = "/Volumes/NO NAME/"
srcSDfolderAlt = sdCardAlt + "DCIM/" # SD folder alternate since both this and one below occur. Used at line 740
srcSDfolder = sdCard + "DCIM/"  # SD folder 

puts "#{lineNum}. lastPhotoReadTextFile: #{lastPhotoReadTextFile}. If script failing may need to change the last file read to 0000 if folder change"
puts "#{lineNum}. srcSDfolder: #{srcSDfolder} which may or may not be the folder being read from"


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

# Folders on portable drive: Daguerre. This is the normal location with Daguerre plugged into iMac
downloadsFolders = "/Volumes/Daguerre/_Download folder/"
# Maybe should start with what computer I'm on then make decisions about what's plugged in. Also consider the 10GB as a primary?
# Process in MtnBikerSSD or Daguerre if plugged in, otherwise the computer in use which is decided later?
if File.exists?(downloadsFolders)
  puts "#{lineNum}. Daguerre is mounted"
else
  downloadsFolders = "/Volumes/MtnBikerSSD/_Download folder/"
  puts "#{lineNum}. Daguerre is NOT mounted, so using #{downloadsFolders}"
end
# See at approx line 985 where decide where to move files
srcHD       = downloadsFolders + " Drag Photos HERE/"  # Photos copied from camera, sent by others, etc.
mylioStaging = downloadsFolders + "Latest Processed photos-Import to Mylio/" #  These are relabeled and GPSed files. Will be moved to Mylio after processing.
# puts "#{lineNum}. mylioStaging: #{mylioStaging}. Where the photos are processed before being moved into Mylio folder" # debugging
tempJpg   = downloadsFolders + "Latest Downloads temp jpg/"
archiveFolder  = downloadsFolders + "_imported-archive" # folder to move originals to if not done in. No slash because getting double slash with one
srcRename = "/Volumes/Seagate 8TB Backup/Mylio_87103a/Greg Scarich’s iPhone Library/" # Frequent location to perfom this. iPhone photos brought into Mylio
#  Below is temporary file location for testing
# srcGpsAdd = HOME + "Documents/◊ Pre-trash/Cheeseboro/" # srcRename # Could to another location for convenience. Debug ??
srcAddLocation  = "/Volumes/Daguerre/_Download folder/Latest Processed photos-Import to Mylio/" # = srcRename # Change to another location for convenience. This location picked so don't screw up a bunch of files

# Mylio folder. Moved to this folder after all processing. Can't process in this folder or Mylio might add before this script's processing is finished. Processing is mainly done in mylioStaging. The following needs to change based on comments at line 79
iMacMylio = HOME + "Mylio/2022/GX8-2022/" # ANNUALLY: ADD IN MYLIO, NOT IN FINDER. Good on both iMac and MBP M1 although it's not under iCloud, so requires Mylio for syncing

lastPhotoReadTextFile = thisScript + "currentData/lastPhotoRead.txt"
puts "#{lineNum}. lastPhotoReadTextFile: #{lastPhotoReadTextFile}. ?? But it's being stored on LUMIX card"

# timeZonesFile = HOME + "Dropbox/scriptsEtc/Greg camera time zones.yml"
timeZonesFile = thisScript + "currentData/Greg camera time zones.yml"
# timeZones = YAML.load(File.read(timeZonesFile)) # read in that file now and get it over with. Only use once, so this just confused things
gpsPhotoPerl = thisScript + "lib/gpsPhoto.pl"

# GPS log files. Will this work from laptop
folderGPX = HOME + "Documents/GPS-Maps-docs/  GPX daily logs/2022 GPX logs/" # Could make it smarter, so it knows which year it is. Massaged contains gpx files from all locations whereas Downloads doesn't. This isn't used by perl script
puts "#{lineNum}. Must manually set folderGPX for GPX file folders. Particularly important at start of new year AND if working on photos not in current year.\n       Using: #{folderGPX}\n"

# MODULES
def ignoreNonFiles(item) # invisible files that shouldn't be processed
  item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon ' or item.slice(0,7) == ".MYLock"
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
    report = "#{lineNum}. #{seconds.to_i} seconds"
  else
    report = "#{lineNum}. #{minutes.to_i} minutes"
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
  puts "\n#{lineNum}. Copying photos from an SD card starting with #{lastPhotoFilename} or from another value manually entered"
  cardCount = 0
  cardCountCopied = 0
  doAgain = true # name isn't great, now means do it. A no doubt crude way to run back through the copy loop if we moved to another folder.
  # timesThrough = 1
  fileSDbasename = "" # got an error at puts fileSDbasename
  while doAgain==true # and timesThrough<=2 
    Dir.chdir(src) # needed for glob
    Dir.glob("P*") do |item| # Presumably filename has to start with 'P'
      cardCount += 1
      print(".") # crude activity bar. This doesn't happen
      # put cardCount # another try at activity bar
      # puts "#{lineNum}.. src/item: #{src}#{item}."
      fn = src + "/" + item # 2019.05.08 added /. Hadn't had it before. Maybe the problem is with src
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
  firstLine = fileSDbasename + " was the last file read on " + Time.now.to_s
  begin
    file_prepend(lastPhotoReadTextFile, firstLine)
    # Following just puts in the last file and wipes out the rest. Can delete all of this
    # fileNow = File.open(lastPhotoReadTextFile, "w") # must use explicit path, otherwise will use wherever we are are on the SD card
    #   fileNow.puts firstLine
    #   fileNow.close
      puts "\n#{lineNum}. The last file processed. fileSDbasename, #{fileSDbasename}, written to  # {fileNow} ??."
  rescue IOError => e
    puts "Something went wrong. Could not write last photo read (#{fileSDbasename}) to #{fileNow}"
  end # begin
    puts "\n#{lineNum}. Of the #{cardCount} photos on the SD card, #{cardCountCopied} were copied to #{src}" # last item was src, doesn't make sense
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

# Checking if a filterEffect or whatever it's called was used, because will use the jpg in Mylio. Also HDR
# def filterEffect(fnp)
#   fileEXIF = MiniExiftool.new(fnp)
#   filterEffect = fileEXIF.FilterEffect
#   puts "\n#{lineNum}. fnp: #{fnp}. FilterEffect: #{filterEffect}"
#   # HDR is "Expressive"
#   if filterEffect == "Expressive" && fileEXIF.HDRShot != "On"
#     jpgMove = true # saying to move, but is this what I want to do NOW. initialized outside this def
#     puts "#{lineNum} FilterEffect: #{filterEffect} == 'Expressive'"
#     FileUtils.rm(fnp) # Removing the jpg file from LatestDownload which is "duplicate" of a RAW that we're now considering. Can comment this out to keep both
#     puts "#{lineNum}.. #{delCount}. fnp: #{itemPrev} will not be added to Mylio because it's a jpg duplicate of a RAW version. But any jpgs from Presets will be missing" # Is this slow? Turned off to try. Not sure.
#     # puts "#{lineNum}.. #{delCount}. fnp: #{itemPrev} was moved to #{tempJpg} it's a jpg duplicate of a RAW version and needs to be processed separately." # Is this slow? Turned off to try. Not sure.
#     delCount += 1
#   else
#     puts "#{lineNum}. #{item} jpg saved to Mylio because the #{filterEffect} effect was used"
#     puts "#{lineNum} FilterEffect: #{filterEffect} == '!Expressive'"
#   end
#   fileEXIF.save
# end

def mylioStageAndArchive(srcHD, mylioStaging, tempJpg, archiveFolder, photosArray)
  # Already copied from SD card, but copying to processing folder (mylioStaging) and then moving the original to archive folder (archiveFolder)
  puts "\n#{lineNum}. Copy photos\nfrom #{srcHD}\n
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
  puts "#{lineNum}. Files in #{srcHD}: #{Dir.entries(srcHD).sort.reverse}" # list of files to be processed
  Dir.entries(srcHD).sort.reverse.each do |item| # This construct goes through each in order. Sometimes the files are not in order with Dir.foreach or Dir.entries without sort. Reverse sorting so can do Raws first
    # Item is the file name
    # puts "\n#{lineNum}.. photoFinalCount: #{photoFinalCount + 1}. item: #{item}." # kind of a progress bar
    next if item == '.' or item == '..' or item == '.DS_Store'
    # next if ignoreNonFiles(item) == true

    fn  = srcHD + item
    fnm = mylioStaging + item
    fna = archiveFolder + item # to already imported for archiving
    itemExt = File.extname(item).downcase

    # if Raw or mp4, copy to staging
    if itemExt != ".jpg"
      FileUtils.copy(fn, fnm)
      puts "#{lineNum}. #{fn} since #{itemExt} is not jpg to be staged"
    end

   # If a jpg and has an effect, copy to mylioStaging via 
    fileEXIF = MiniExiftool.new(fn)
    filterEffect = fileEXIF.FilterEffect
    if itemExt.downcase == ".jpg" && filterEffect != "Expressive" # Expressive is default, so not much of an effect, but may need to change this
      # filterEffect(fnp) # if decide to do more with this
      fnt = tempJpg + item
      FileUtils.copy(fn, fnt)
      puts "#{lineNum}. #{fn} to be staged since filterEffect is #{filterEffect}"
    end
    
    # if two jpgs in a row, then no associated raw, therefore stage
    if itemPrevExtName == itemExt
      fnt = tempJpg + item
      FileUtils.copy(fn, fnt)
      puts "#{lineNum}. #{fn} to be staged since #{itemPrevExtName} == #{itemExt} was #{itemPrevExtName == itemExt}"
    end

    itemPrevExtName = itemExt # since reusing below. jpg, orf (Olympus) or RW2 (Panasonic). So will work as long as Raw comes after jpg alphabetically

    if File.exists?(fna)  # moving the original to _imported-archive, but not writing over existing files
      fna = uniqueFileName(fna)
      FileUtils.move(fn, fna)
      puts "#{lineNum}. A file already existed with this name so it was changed to fna: #{fna}"
    else # no copies, so move
      FileUtils.move(fn, fna)
    end # File.exists?
      # "#{lineNum}.. #{photoFinalCount + delCount} #{fn}" # More for debugging, but maybe OK as progress in this slow process
    photoFinalCount += 1
    arrayIndex = photoFinalCount - 1 # Need spaces around the minus
    photosArray << [arrayIndex, item, fnm, itemPrevExtName] # count minus one, so indexed like an array starting at zero
    print "." # Trying to get a progress bar
  end # Dir.entries
  # puts "\#{lineNum}. #{photoFinalCount} photos have been moved and are ready for renaming and gpsing. #{delCount-1} duplicate jpg were not
  if delCount > 1
    comment = "#{lineNum}. #{delCount-1} jpegs were moved to #{tempJpg} for processing separately."
  else
    comment = ""
  end # if delCount
  puts "\n#{lineNum}. #{photoFinalCount} photos have been moved and are ready for renaming and adding GPS coordinates \n#{comment}"
  return photosArray
end # mylioStageAndArchive: copy to the final destination where the renaming will be done and coordinates added; and the original moved to an archive (_imported-archive folder)

# Before reverse but was not working
# def mylioStageAndArchive(srcHD, mylioStaging, tempJpg, archiveFolder, photosArray)
#   # Already copied from SD card, but copying to processing folder (mylioStaging) and then moving the original to archive folder (archiveFolder)
#   puts "\n#{lineNum}. Copy photos\nfrom #{srcHD}\n
#   to #{mylioStaging} where the renaming will be done, \n
#   and the originals moved to an archive folder (#{archiveFolder})"
#   # Only copy jpg to mylioStaging if there is not a corresponding raw, but keep all taken files. With Panasonic JPG comes before RW2
#   # Guess this method is slow because files are being copied
#   # THIS METHOD WILL NOT WORK IF THE RAW FILE FORMAT ALPHABETICALLY COMES BEFORE JPG. SHOULD MAKE THIS MORE ROBUST
#   photoFinalCount = 0
#   delCount = 1
#   itemPrev = "" # need something for first time through
#   fnp = ""
#   jpgMove = false # Define outside of the 'each do' loop
#   # puts "#{lineNum}. Files in #{srcHD}: #{Dir.entries(srcHD).sort}" # list of files to be processed
#   Dir.entries(srcHD).sort.each do |item| # This construct goes through each in order. Sometimes the files are not in order with Dir.foreach or Dir.entries without sort
#     # Item is the file name
#     # puts "\n#{lineNum}.. photoFinalCount: #{photoFinalCount + 1}. item: #{item}." # kind of a progress bar
#     next if item == '.' or item == '..' or item == '.DS_Store'
#     # next if ignoreNonFiles(item) == true
#
#     fn  = srcHD + item
#     fnm = mylioStaging + item
#     fnf = archiveFolder + item # to already imported for archiving
#
#    # If a jpg and has an effect, copy to mylioStaging
#     itemExt = File.extname(item)
#     fileEXIF = MiniExiftool.new(item)
#     filterEffect = fileEXIF.FilterEffect
#     if itemExt.downcase == ".jpg" && filterEffect != "Expressive" # Expressive is default, so not much of an effect, but may need to change this
#       FileUtils.copy(fn, fnm)
#       # filterEffect(fnp) # if decide to do more with this
#     end
#
#     # If first pair are jpgs or Raws, the previous one needs to be saved as it is jpg only or an HDR
#     if photoFinalCount == 1 && itemPrevExtName == itemExt # checks if a Raw and jpg exist, but skips first time through
#       #  The following shouldn't be necessary, but is a check in case another kind of raw or who know what else. Only the FileUtils.rm(itemPrev) should be needed
#         FileUtils.copy(fnp, fnmp)
#     else # not the same
#
#     # Already screened for ones with effect above, now just delete any jpgs without a Raw
#     # If jpg's into Mylio if a Raw exists, First check if basenames are the same
#     # Then if Raw, copy. Skip if jpg
#     if File.basename(itemPrev, ".*") == File.basename(item,".*") && photoFinalCount != 0 # checks if a Raw and jpg exist, but skips first time through
#       #  The following shouldn't be necessary, but is a check in case another kind of raw or who know what else. Only the FileUtils.rm(itemPrev) should be needed
#       if itemExt.downcase != ".jpg" # that is raw
#         FileUtils.copy(fn, fnm)
#       end
#     else # not the same
#
#     # What about solo jpg, either an HDR or only shot jpg for some reason
#
#       itemPrevExtName = File.extname(itemPrev) # since reusing below. jpg, orf (Olympus) or RW2 (Panasonic). So will work as long as Raw comes after jpg alphabetically
#       fnp = fn
#       fnpm = fnm
#       # TODO Add an option to keep or not keep jpgs. May want to see how camera is converting them. May end up having problem with labeling as then would have two photos taken at the same time and the Raw will always be a .b
#         # FileUtils.rm(mylioStaging + itemPrev) if itemPrevExtName == ".HEIC" # could uncomment this if a problem for Mylio.
#       #  Not sure about what how to handle HEIC
#       # if itemPrevExtName.downcase ==  ".jpg"
#         # photoFinalCount -= 1 # commented out since now included
#       # else # not a jpg and check for HEIC--what am I doing with this
#     #     if itemPrevExtName == ".HEIC"
#     #       FileUtils.rm(mylioStaging + itemPrev)
#     #     end # itemPrevExtName-just one line
#     #     puts "#{lineNum}. Something very wrong here with trying to remove JPGs when there is a corresponding .RW2 or .HEIC. itemPrev: #{itemPrev}. item: #{item}."
#     #   end # itemPrevExtName.downcase a bunch of lines
#       # end # File.extname
#     end   # File.basename
#     # fn  = srcHD       + item # sourced from Drag Photos Here
#    #  fnm = mylioStaging + item # new file in Latest Download
#     # fnm = tempJpg     + item if !jpgMove # seems like ! is backwards but this works
#     # FileUtils.copy(fn, fnm) if fn!=fnp # making a copy in the mylioStaging folder for further action
#
#     if File.exists?(fnf)  # moving the original to _imported-archive, but not writing over existing files
#       fnf = uniqueFileName(fnf)
#       FileUtils.move(fn, fnf)
#       puts "#{lineNum}. A file already existed with this name so it was changed to fnf: #{fnf}"
#     else # no copies, so move
#       FileUtils.move(fn, fnf)
#     end # File.exists?
#       # "#{lineNum}.. #{photoFinalCount + delCount} #{fn}" # More for debugging, but maybe OK as progress in this slow process
#       itemPrev = item
#       jpgMove = false
#       photoFinalCount += 1
#       arrayIndex = photoFinalCount - 1 # Need spaces around the minus
#       photosArray << [arrayIndex, item, fnm, itemPrevExtName] # count minus one, so indexed like an array starting at zero
#       print "." # Trying to get a progress bar
#
#   end # Dir.entries
#   # puts "\#{lineNum}. #{photoFinalCount} photos have been moved and are ready for renaming and gpsing. #{delCount-1} duplicate jpg were not
#   if delCount > 1
#     comment = "#{lineNum}. #{delCount-1} jpegs were moved to #{tempJpg} for processing separately."
#   else
#     comment = ""
#   end # if delCount
#   puts "\n#{lineNum}. #{photoFinalCount} photos have been moved and are ready for renaming and adding GPS coordinates \n#{comment}"
#   return photosArray
# end # mylioStageAndArchive: copy to the final destination where the renaming will be done and coordinates added; and the original moved to an archive (_imported-archive folder)

# def unmountCard(card)
#   puts "#{lineNum}. card: #{card}"
#   card = card[-8, 7]
#   puts "#{lineNum}. card: #{card}"
#   card  = "\"" + card + "\""
#   disk =  `diskutil list |grep #{card} 2>&1`
#   puts "\n#{lineNum}. disk: #{disk}"
#   # Getting confused because grabbing the last 7 twice. And naming sucks (mjy fault)
#   driveID = disk[-8, 7] # not sure this syntax is precise, but it's working.
#   puts "#{lineNum} Unmount #{card}. May have to code this better. See if card name is already a variable. This is hard coded for a specific length of card name"
#   puts "#{lineNum}. driveID: #{driveID}. card: #{card}"
#   cmd =  "diskutil unmount #{driveID} 2>&1"
#   puts "cmd: #{cmd}"
#   unmountResult = `diskutil unmount #{driveID} 2>&1`
#   puts "\n#{lineNum}. SD card, #{unmountResult}, unmounted."
# end #unm

def userCamCode(fn)
  fileEXIF = MiniExiftool.new(fn)
  ## not very well thought out and the order of the tests matters
  case fileEXIF.model
    when "DMC-GX8"
      userCamCode = ".gs.P" # gs for photographer. P for *P*anasonic Lumix
    when "iPhone 13"
      userCamCode = "gs.i" # gs for photographer. i for iPhone
    when "iPhone X"
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

def fileAnnotate(fn, fileDateTimeOriginalstr, tzoLoc)
  # Called from rename
  # writing original filename and dateTimeOrig to the photo file.
  fileEXIF = MiniExiftool.new(fn)
  if tzoLoc.to_i < 0
    tzoLocPrint = tzoLoc
  else
    tzoLocPrint = "+" + tzoLoc.to_s
  end
  fileEXIF.instructions = "#{fileDateTimeOriginalstr} #{tzoLocPrint})" if !fileEXIF.DateTimeStamp # Time zone of photo is GMT #{tzoLoc} unless TS5?" or travel. TODO find out what this field is really for
  # fileEXIF.comment = "Capture date: #{fileDateTimeOriginalstr} UTC. Time zone of photo is GMT #{tzoLoc}. Comment field" # Doesn't show up in Aperture
  # puts "#{lineNum}. fileEXIF.source: #{fileEXIF.source}.original file basename not getting written"
  # puts "#{File.basename(fn)} original filename to be written to EXIF.title"
  fileEXIF.PreservedFileName = "#{File.basename(fn)}" # title ends up as Title above the caption. Source shows up in exiftool as IPTC::Source
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
  # puts "#{lineNum}. timeZones:  #{timeZones}."
  timeZones = YAML.load(File.read(timeZonesFile)) # should we do this once somewhere else? Let's try that in this new version
  # puts "#{lineNum}. timeZones.keys:  #{timeZones.keys}."
  i = timeZones.keys.max # e.g. 505
  j = timeZones.keys.min # e.g. 488
  while i > j # make sure I really get to the end 
    theTime = timeZones[i]["timeGMT"]
    # puts "\n#{lineNum}. (last entry in timeZonesFile) i: #{i}. theTime (of the last entry in GMT): #{theTime}. theTime.class: #{theTime.class}" # i: 502. theTime: 2011-06-29T01-00-00Z. theTime.class: String
    theTime = Time.parse(theTime) # class: time Wed Jun 29 00:00:00 -0700 2011. Time.parse only seems to do the date part
    # puts "\n#{lineNum}. #{i}. fileDateTimeOriginal: #{fileDateTimeOriginal}. theTime (in local time): #{theTime}. fileDateTimeOriginal.class: #{fileDateTimeOriginal.class}. theTime.class: #{theTime.class}"
    # puts "Note that these dates are supposed to be UTC, but are getting my local time zone attached."
    if fileDateTimeOriginal.to_s > theTime.to_s # What if neither was to_s? TODO
      theTimeZone = timeZones[i]["zone"]
      # puts "#{lineNum}. #{i}. fileDateTimeOriginal: #{fileDateTimeOriginal} fileDateTimeOriginal.class: #{fileDateTimeOriginal.class}. theTimeZone: #{theTimeZone}."
      return theTimeZone
    else
      i= (i.to_i-1).to_s
    end
  end # loop
  # theTimeZone = -2 # Was changed on MBP, don't know if needed there or it was a one off
  # puts "#{lineNum}. #{i}. fileDateTimeOriginal: #{fileDateTimeOriginal} fileDateTimeOriginal.class: #{fileDateTimeOriginal.class}. theTimeZone: #{theTimeZone}. "  return theTimeZone
end # timeZone

def rename(src, timeZonesFile, timeNowWas)
  # src is mylioStaging folder
  # timeZonesFile is my log of which time zones I was in when
  # timeNowWas used for timing various parts of the script. 
  # Until 2017, this assumed camera on UTC, but doesn't work well for cameras with a GPS or set to local time
  # So have to ascertain what time zone the camera is set to by other means in this script, none of them foolproof
  # 60 minutes for ~1000 photos to rename TODO ie, very slow
  fn = fnp = fnpPrev = "" # must declare variable or they won't be available everywhere in the module
  subSecPrev = subSec = ""
  fileDatePrev = ""
  dupCount = 0
  count    = 1
  tzoLoc = ""
  seqLetter = %w(a b c d e f ) # used when subsec doesn't exist
  # puts "#{lineNum}. Entered rename and ready to enter foreach. src: #{src}"
  Dir.foreach(src) do |item| # for each photo file
    next if ignoreNonFiles(item) == true # skipping file when true, i.e., not a file
    # puts "#{lineNum}. File skipped because already renamed, i.e., the filename starts with 20xx #{item.start_with?("20")}"
    next if item.start_with?("20") # Skipping files that have already been renamed.
    next if item.end_with?("xmp") # Skipping .xmp files in Mylio and elsewhere. The files may become orphans
    # puts "#{lineNum}. #{src} " # #{timeNowWas = timeStamp(timeNowWas)}
    puts "#{lineNum}. #{item} will be renamed. " # #{timeNowWas = timeStamp(timeNowWas)}
    fn = src + item # long file name
    fileEXIF = MiniExiftool.new(fn) # used several times
    # fileEXIF = Exif::Data.new(fn) # see if can just make this change, probably break something. 2017.01.13 doesn't work with Raw, but developer is working it.
    camModel = fileEXIF.model

    # To add display for Mylio
    filterEffect = fileEXIF.FilterEffect
    if File.extname(item).downcase == ".jpg" && filterEffect != "Expressive" # Expressive is default, so not much of an effect, but may need to change this
      filtered = "_display"
    else
      filtered = ""
    end

    # puts "\n#{lineNum}. #{fileCount}. fn: #{fn}"
    # puts "#{lineNum}.. File.file?(fn): #{File.file?(fn)}. fn: #{fn}"
    # if !File.file?(fn) # Take out when figure it out.
    #   puts "#{lineNum}. Checking why the check below is needed. File.file?(fn): #{File.file?(fn)} for fn: #{fn}"
    # end
    if File.file?(fn) # why is this needed. Do a check above
      # Determine the time and time zone where the photo was taken
      # puts "#{lineNum}.. fn: #{fn}. File.ftype(fn): #{File.ftype(fn)}." #  #{timeNowWas = timeStamp(timeNowWas)}
      fileExt = File.extname(fn).tr(".","").downcase  # needed later for determining if dups at same time. Will be lowercase jpg or rw2 or whatever
      fileExtPrev = ""
      fileDateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
      # puts "#{lineNum}. fileDateTimeOriginal = fileEXIF.dateTimeOriginal: #{fileDateTimeOriginal} of class: #{fileDateTimeOriginal.class}"
      # 446. fileDateTimeOriginal = fileEXIF.dateTimeOriginal: 2021-11-25 12:09:11 -0800 of class: Time. This was really -7, but computer is -8, and that is what is reported. The dateTimeOriginal in the camera doesn't know what zone it's in.
      fileSubSecTimeOriginal = fileEXIF.SubSecTimeOriginal # no error if doesn't exist
      subSec = "." + fileSubSecTimeOriginal.to_s[0..1] #Truncating to 2 figs (could round but would need to make a float, divide by 10 and round or something. This should be close enough)
      subSecExists = fileEXIF.SubSecTimeOriginal.to_s.length > 2 # 
      if fileDateTimeOriginal == nil 
        # TODO This probably could be cleaned up, but then normally not used, movie files don't have this field
        fileDateTimeOriginal = fileEXIF.DateCreated  # PNG don't have dateTimeOriginal
        camModel ="MISC" # Dummy value for test below
        fileDateTimeOriginal == nil ? fileDateTimeOriginal = fileEXIF.CreationDate : "" # now fixing .mov files
        fileDateTimeOriginal == nil ? fileDateTimeOriginal = fileEXIF.MediaCreateDate : "" # now fixing .mp4 files. Has other dates, but at least for iPhone mp4s the gps info exists
      end # if fileDateTimeOriginal == nil
      panasonicLocation = fileEXIF.location # Defined by Panasonic if on trip (and also may exist for photos exported from other apps such as Photos). If defined then time stamp is that local time
      # puts "#{lineNum}. panasonicLocation: #{panasonicLocation}"
      tzoLoc = timeZone(fileDateTimeOriginal, timeZonesFile ) # the time zone the picture was taken in, doesn't say anything about what times are recorded in the photo's EXIF. I'm doing this slightly wrong, because it's using the photo's recorded date which could be either GMT or local time. But only wrong if the photo was taken too close to the time when camera changed time zones
      # puts "#{lineNum}. #{count}. tzoLoc: #{tzoLoc} from timeZonesFile"
      if count == 1 | 1*100 # only gets written every 100 files.
        puts "#{lineNum}. panasonicLocation: #{panasonicLocation}. tzoLoc: #{tzoLoc}. Time zone photo was taken in from Greg camera time zones.yml\n"
      # else
      #   print "."
      end # count
      # count == 1 | 1*100 ?  :  puts "."  Just to show one value, otherwise without if prints for each file; now prints every 100 time since this call seemed to create some line breaks and added periods.
      # Also determine Time Zone TODO and write to file OffsetTimeOriginal	(time zone for DateTimeOriginal). Either GMT or use tzoLoc if recorded in local time as determined below
      # puts "#{lineNum}.. camModel: #{camModel}. #{tzoLoc} is the time zone where photo was taken. Script assumes GX8 on local time "
      # Could set timeChange = 0 here and remove from below except of course where it is set to something else
      timeChange =  0 # 3600 *  # setting it outside the loops below and get reset each time through. But can get changed
      # puts "#{lineNum}. camModel: #{camModel}. fileEXIF.OffsetTimeOriginal: #{fileEXIF.OffsetTimeOriginal}"
      if camModel ==  "MISC" # MISC is for photos without fileDateTimeOriginal, e.g., movies
        # timeChange = 0
       fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
       puts "#{lineNum}.. fileDateTimeOriginal #{fileDateTimeOriginal}. timeChange: #{timeChange} for #{camModel} meaning movies"
      elsif camModel == "DMC-TS5" or camModel == "DMC-GX8"
      # elsif camModel.include?("DMC-GX7") and panasonicLocation.length > 0 or camModel == "DMC-TS5" or camModel == "DMC-GX8" # Not sure what the first check was, but GX& isn't being used anymore so took it out. Was giving an error for a jpg created by QuickTime Player 2021.07.15. DateTimeOriginal is in local time. Look at https://sno.phy.queensu.ca/~phil/exiftool/TagNames/Panasonic.html for other Tags that could be used
        # Above first checking that is a Panasonic Lumix GX7 using travel, otherwise will error on second test which checks if using travel, 
        ### first criteria won't work for files exported from another app using GX7
        # timeChange = 0
        fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
#       puts "#{lineNum}: camModel: #{camModel}. tzoLoc: #{tzoLoc}. timeChange.class: #{timeChange.class} timeChange: #{timeChange.to_i}"
        puts "#{lineNum}. fileDateTimeOriginal #{fileDateTimeOriginal}. timeChange: #{timeChange} for #{camModel}"
      elsif camModel == "iPhone X"  # DateTimeOriginal is in local time
        # timeChange = 0
        fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
        timeChange = (3600*tzoLoc) # previously had error capture on this. Maybe for general cases which I'm not longer covering
        fileEXIF.OffsetTimeOriginal = "GMT"
        puts "#{lineNum}.. fileDateTimeOriginal #{fileDateTimeOriginal}. timeChange: #{timeChange} for #{camModel}" if count == 1 # just once is enough
      end # if camModel
      fileEXIF.save # only set OffsetTimeOriginal, but did do some reading.     

      fileDate = fileDateTimeOriginal + timeChange.to_i # date in local time photo was taken. No idea why have to change this to i, but was nil class even though zero  
      fileDateTimeOriginalstr = fileDateTimeOriginal.to_s[0..-6]
      
      # filePrev = fn
      # Working out if files at the same time
      # puts "\nxx.. #{fileCount}. oneBack: #{oneBack}."
      # Determine dupCount, i.e., 0 if not in same second, otherwise the number of the sequence for the same time
      # puts "#{lineNum}.. #{timeStamp(timeNowWas)}"
      # Now the fileBaseName. Simple if not in the same second, otherwise an added sequence number
      # oneBack = fileDate == fileDatePrev # true if previous file at the same time calculated in local time
      oneBack = fileDate == fileDatePrev && fileExt != fileExtPrev # at the moment this is meaningless because all of tne type
      # puts "\n#{lineNum}.#{count}. oneBack: #{oneBack}. #{item}. dupCount: #{dupCount}"
      # if subSecExists # mainly GX8. Too heavy handed, every GX8 files get subSec which is too much
#           fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + "." + fileSubSecTimeOriginal.to_s + userCamCode(fn)
#           puts "#{lineNum}. fn: #{fn} in 'if subSecExists'.     fileBaseName: #{fileBaseName}."
      # else # not GX8
      if oneBack # at the moment only handles two in the same second
        dupCount += 1
        if subSecExists # mainly GX8. and maybe iPhone bursts
          fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  subSec + userCamCode(fn) # this doesn't happen for the first one in the same second.
          # puts "#{lineNum}. fn: #{fn} in 'if subSecExists'.     fileBaseName: #{fileBaseName}. dupCount: #{dupCount}"
          if dupCount == 1
            # Can use old fileDate because it's the same and userCamCode. 
            fnp = src + fileDate.strftime("%Y.%m.%d-%H.%M.%S") + subSecPrev + userCamCode(fn)+  File.extname(fn).downcase
            # puts "#{lineNum}. We will relabel #{fnpPrev} to #{fnp} since it didn't get subSecPrev: #{subSecPrev}. dupCount: #{dupCount} "
            File.rename(fnpPrev,fnp)
          end # if dup count
        else # photos without subsecs, pre GX8
          fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  seqLetter[dupCount] + userCamCode(fn) + filtered
          puts "#{lineNum}. fn: #{fn} in 'if oneBack'.     fileBaseName: #{fileBaseName}."
        end # subSecExists
        # fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  seqLetter[dupCount] + userCamCode(fn)
#           puts "#{lineNum}. fn: #{fn} in 'if oneBack'.     fileBaseName: #{fileBaseName}."
      else # normal condition that this photo is at a different time than previous photo
        dupCount = 0 # resets dupCount after having a group of photos in the same second
        fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S")  + userCamCode(fn) + filtered
        # puts "#{lineNum}. item: #{item} is at different time as previous.    fileBaseName: #{fileBaseName}"
      end # if oneBack
      # end # if subSecExists
      fileDatePrev = fileDate
      fileExtPrev = fileExt
      # fileBaseNamePrev = fileBaseName

      # File renaming and/or moving happens here
      # puts "#{lineNum}. #{count+1}. dateTimeOriginal: #{fileDateTimeOriginal}. item: #{item}. camModel: #{camModel}" # . #{timeNowWas = timeStamp(timeNowWas)}
      # fileAnnotate(fn, fileEXIF, fileDateTimeOriginalstr, tzoLoc) # adds original file name, capture date and time zone to EXIF. Comments which I think show up as instructions in Aperture. Also wiping out bad GPS data on TS5
      fileAnnotate(fn, fileDateTimeOriginalstr, tzoLoc) # was passing fileEXIF, but saving wasn't happening, so reopen in the module?
      # #### Doing here for one round Didn't work
      # fileEXIF.title = "#{File.basename(fn)} original filename" # Source OK, but Title seemed a bit better
     #  puts "#{lineNum}. File.basename(fn): #{File.basename(fn)}. Supposed to be written to photo"
     #  fileEXIF.save

      fnp = fnpPrev = src + fileBaseName + File.extname(fn).downcase # unless #Why was the unless here?
      # puts "Place holder to make the script work. where did the unless come from"
#       puts "#{lineNum}. fn: #{fn}. fnp (fnpPrev): #{fnp}. subSec: #{subSec}"
      subSecPrev = subSec.to_s
      File.rename(fn,fnp)
      count += 1
      # print " #{count}" Trying for  progress indicator
      # puts "#{lineNum}.#{count} #{timeNowWas = timeStamp(timeNowWas)}. #{fileBaseName}" # temp to see how long taking. 1 to 4 seconds on MBP accessing photos on attached portable drive
    else
      puts "#{lineNum}. CHECKING why `if File.file?(fn)` is needed. File.file?(fn): #{File.file?(fn)} for fn: #{fn}"
    end # 3. if File.file?(fn)
    # puts "#{lineNum}. Got to here. tzoLoc: #{tzoLoc}"
    
  end # 2. Dir.foreach(src)
  # return tzoLoc # used by ?
  # puts "#{lineNum}. Got to here. tzoLoc: #{tzoLoc}" # tzoLoc doesn't exist here
  return tzoLoc # the time zone the picture was taken in,
end # rename ing photo files in the downloads folder and writing in original time.

def addCoordinates(photoFolder, folderGPX, gpsPhotoPerl, tzoLoc)
  # Remember writing a command line command, so telling perl, then which perl file, then the gpsphoto.pl script options
  # --timeoffset seconds     Camera time + seconds = GMT. No default.  
  # maxTimeDiff = 50000 # seconds, default 120, but I changed it 2011.07.26 to allow for pictures taken at night but GPS off. Distance still has to be reasonable, that is the GPS had to be at the same place in the morning as the night before as set by the variable below
  # This works, put in because having problems with file locations
  # perlOutput = `perl \"#{gpsPhotoPerl.shellescape}\" --dir #{photoFolder.shellescape} --gpsdir #{folderGPX.shellescape} --timeoffset 0 --maxtimediff 50000 2>&1`
  
  # photoFolder is where the photos are that are going to have gps coordinates added. A temporary location. Usually called mylioStaging is the overall script
  # folderGPX is where the gpx tracks are
  # gpsPhotoPerl is where gpsPhoto.pl is
  # tzoLoc is the time zone from Greg camera time zones.yml file. Since GPS records UTM. Camera time zone setting varies. Camera only recordeds the time it is set for, but doesn't accurately report the zone. Currently exiftool is saying the zone is the zone of the computer running the script. tzoLoc value can be changed in this module. tzoLoc is hours and gets changed to seconds as timeOffset for use by gpsPhoto.pl
  # <--timeoffset seconds> A positive value means that the camera is behind in time, a negative value means that the camera is ahead in time.
  

# Assuming all the photos are from the same camera, get info on one and use that information.
# GX8 is usually local time, but may get
# GX7 is UST
  camModel = ""
  timeOffset = 0
  Dir.foreach(photoFolder) do |item|
    # This is only run once, so efficiency doesn't matter
    count = 0
    next if ignoreNonFiles(item)  # skipping file when true == true
    fn = photoFolder + item
    fileEXIF = MiniExiftool.new(fn) # used several times
    camModel = fileEXIF.model
    # puts "#{lineNum}. model: #{camModel} fn: #{fn}" # debug
    panasonicLocation = fileEXIF.location
    # timeOffset = 0 # could leave this in and remove the else 
    if File.file?(fn)
      if camModel == "DMC-GX8" # Assumes GX8 always on local time. And TimeZone is set
        # timeOffset = tzoLoc * 3600 # old way which may be fine, but the following seems more direct. May not account for camera not being in the zone it's set for, but I don't think that matters. It matters for time labeling, but this is only GPS coords
        timeOffset =  (fileEXIF.TimeStamp -  fileEXIF.CreateDate) # seconds, so how much GMT is ahead of local. So opposite time zone
        puts "#{lineNum}. timeOffset: #{timeOffset} seconds (#{timeOffset/3600} hours) with GX-8 photos stamped in local time. FYI: tzoLoc: #{tzoLoc} per zones file which isn't being used for coordinates but seems like it could with hrs to secs change."
        # timeOffset = 3600 * 7
        # puts "#{lineNum}. Hardwired to #{timeOffset} seconds for this run"

      elsif camModel.include?("DMC") and panasonicLocation.length > 0 # Panasonic in Travel Mode, but also some photos exported from Photos.
        timeOffset = tzoLoc * 3600
        puts "#{lineNum}. timeOffset: #{timeOffset} sec (#{tzoLoc} hours) with photos stamped in local time."
      elsif camModel  == "DMC-TS5"
        # Offset sign is same as GMT offset, eg, we are -8, but need to increase the time to match UST, therefore negative
        timeOffset = - fileEXIF.dateTimeOriginal.utc_offset # Time zone is set in camera, i.e. local time in this case
        # What does utc_offset do for the above. dateTimeOriginal is just a time, e.g., 2018:12:31 21:38:32, which is the time the camera thinks it is. Camera doesn't know about zone. Camera may, but from dateTimeOriginal, can't tell the time zone.
        puts "#{lineNum}. timeOffset: #{timeOffset} for DMC-TS5 photos stamped in local time."
      else # GX7 time is UTC. iPhone ends up here too
        timeOffset = 0 # camelCase, but perl variable is lowercase
        puts "#{lineNum}. timeOffset: #{timeOffset} sec (#{tzoLoc} hours) with photos stamped in GMT"
      end # if camModel
      # puts "#{lineNum} timeOffset: #{timeOffset} triple checking"
      fileEXIF.save 
      count += 1
    end # if File.file
    break if count == 1 # once have a real photo file, can get out of this. Only check htis once
  end # Dir.foreach
  puts "#{lineNum}. timeOffset: #{timeOffset}. camModel: #{camModel}. All photos must be same camera and time zone or photos may be mislabeled and geo-located."
   
  puts "\n#{lineNum}. Finding all gps points from all the gpx files using gpsPhoto.pl. This may take a while. \n"
  # Since have to manually craft the perl call, need one for with Daguerre and one for on laptop
  # Daguerre version. /Volumes/Daguerre/_Download folder/Latest Download/
  
  perlOutput = `perl '#{gpsPhotoPerl}' --dir '#{photoFolder}' --gpsdir '#{folderGPX}' --timeoffset #{timeOffset} --maxtimediff 50000`
  # The following is identical, so apparently was taken care of elsewhere. So now use the single line above
    # if loadingToLaptop
    #   # perlOutput = `perl '/Users/gscar/Documents/Ruby/Photo\ handling/lib/gpsPhoto.pl' --dir '/Users/gscar/Pictures/_Photo Processing Folders/Processed\ photos\ to\ be\ imported\ to\ Aperture/' --gpsdir '/Users/gscar/Dropbox/\ GPX\ daily\ logs/2017\ Massaged/' --timeoffset #{timeOffset} --maxtimediff 50000` # saved in case something goes wrong. This works
    #   perlOutput = `perl '#{gpsPhotoPerl}' --dir '#{photoFolder}' --gpsdir '#{folderGPX}' --timeoffset #{timeOffset} --maxtimediff 50000`
    # else # default location on Daguerre or Knobby Aperture Two
    #   # perlOutput = `perl '/Users/gscar/Documents/Ruby/Photo\ handling/lib/gpsPhoto.pl' --dir '/Volumes/Knobby Aperture Two/_Download\ folder/Latest\ Download/' --gpsdir '/Users/gscar/Dropbox/\ GPX\ daily\ logs/2017\ Massaged/' --timeoffset #{timeOffset} --maxtimediff 50000` # this works, saving in case the following doesn't
    #   perlOutput = `perl '#{gpsPhotoPerl}' --dir '#{photoFolder}' --gpsdir '#{folderGPX}' --timeoffset #{timeOffset} --maxtimediff 50000`
    #   # Double quotes needed for variables to be evalated
    #   # perlOutput = "`perl \'#{gpsPhotoPerl.shellescape}\' --dir \'#{photoFolder.shellescape}\' --gpsdir \'#{folderGPX.shellescape}\' --timeoffset #{timeOffset} --maxtimediff 50000`" #  2>&1
    #   # perlOutput = "`perl '/Users/gscar/Documents/Ruby/Photo\ handling/lib/gpsPhoto.pl' --dir '/Volumes/Knobby Aperture Two/_Download\ folder/Latest\ Download/' --gpsdir '/Users/gscar/Dropbox/\ GPX\ daily\ logs/2017\ Massaged/' --timeoffset #{timeOffset} --maxtimediff 50000 2>&1` " #  2>&1 is needed to capture output, but not to run
    #
    #   puts "#{lineNum}. perlOutput: #{perlOutput}"
    # end
      
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
# puts "#{lineNum}. mylioStaging: #{mylioStaging}" # debugging
def moveToMylio(mylioStaging, mylioFolder, timeNowWas)
  puts "\n#{lineNum}. Moving processed photos from #{mylioStaging} to Mylio folder #{mylioFolder}"
  Dir.foreach(mylioStaging) do |item|
    fn  = mylioStaging + item # mylioStaging is now temporary destination, so nomenclature is weird
    fnp = mylioFolder + item
    # puts "#{lineNum}.#{jpgsMovedCount += 1}. #{fn} moved to #{fnp}" # dubugging
    next if ignoreNonFiles(item) == true # skipping file when . or ..
    FileUtils.move(fn, fnp)
  end
  puts "Photos moved to Mylio folder, #{mylioFolder}, where they will automagically be imported into Mylio."
  puts "All done! #{timeNowWas}"
end

## The "PROGRAM" ############ ##################### ###################### ##################### ##########################
timeNowWas = timeStamp(Time.now, lineNum) # Initializing. Later calls are different
# timeNowWas = timeStamp(timeNowWas)
puts "Are the gps logs up to date?" # Should check for this since I don't see the message
puts "FileUtilse naming and moving started  . . . . . . . . . . . . " # for trial runs  #{timeNowWas}

# Two names for SD cards seem common
unless File.directory?(srcSDfolder) # negative if, so if srcSDfolder exists skip, other wise change reference to …Alt
  srcSDfolder = srcSDfolderAlt
  sdCard      = sdCardAlt
end

# need to determine this based on last file and that will have to be later Which has been done so commented out 2019.07.20
# srcSD = srcSDfolder + sdFolder(sdFolderFile)

# if Daguerre isn't mounted use folders on laptop. 
if File.exists?(downloadsFolders)
  puts "#{lineNum}. Using Daguerre or MtnBikerSSD. File.exists?(downloadsFolders (#{downloadsFolders})): #{File.exists?(downloadsFolders)}"
else
   puts "\n#{lineNum}. #{downloadsFolders} isn't mounted, so will use local laptop folders to process"
  # Daguerre folders location loaded by default, changed as needed
  downloadsFolders = laptopDownloadsFolder # line ~844
  mylioStaging        = laptopDestination
  archiveFolder         = laptopDestOrig
  tempJpg          = laptopTempJpg
  srcHD            = downloadsFolders # is this being used?
  # loadingToLaptop = true # No longer used
end

# Check if photos are already in Latest Download folder. A problem because they get reprocessed by gps coordinate adding.
folderPhotoCount = Dir.entries(mylioStaging).count - 3 # -3 is a crude way to take care of ., .., .. Crude is probably OK since this isn't critical. If one real photo is there, not a big problem
if folderPhotoCount > 0
  # puts "#{lineNum}. downloadsFolders: #{downloadsFolders}. Check if Pashua warning window appears"
  # downloadsFolderEmpty(mylioStaging, folderPhotoCount) # Pashua window
else
  puts "\n#{lineNum}. 'Processed photos to be imported to Mylio/' folder is empty and script will continue."
end

# Ask whether working with photo files from SD card or HD
# fromWhere are the photos?
fromWhere = whichLoc() # This is pulling in first Pashua window (1. ), SDorHD.rb which has been required # 
# puts "#{lineNum}. fromWhere: #{fromWhere}" #{"rename"=>"1", "whichDrive"=>"SD card to be selected in the next window", "gpsLocation"=>"0", "gpsCoords"=>"0", "cb"=>"0"}
# puts "\n#{lineNum}. fromWhere[\"rename\"]: #{fromWhere["rename"]}"
# puts "#{lineNum}. fromWhere[\"gpsCoords\"]: #{fromWhere["gpsCoords"]}"
# puts "#{lineNum}. fromWhere[\"gpsLocation\"]: #{fromWhere["gpsLocation"]}"
whichDrive = fromWhere["whichDrive"][0].chr # only using the first character
# A: already downloaded. S: SD card. 
# puts "\n#{lineNum}.. whichDrive: #{whichDrive}. (A: already downloaded. S: SD card.)" #\nWill convert to SD or HD
# Set the return into a more friendly variable and set the src of the photos to be processed
whichOne = whichOne(whichDrive) # parsing result to get HD or SD
# puts "#{lineNum}. fromWherefromWhere: #{fromWhere}. whichDrive: #{whichDrive}. whichOne: #{whichOne}" # fromWhere not defined
# Only rename files in place and skip the rest. Not sure right location because not sure about when Pashua is run
# puts "#{lineNum}. whichOne: #{whichOne}" # debug
# # puts whichLoc()

# Getting the folder selected in the dialog box, but also sending the default

# Three options for partial processing, then go to either HD or SD
# Option for renaming files while not moving photos
# Now the logic is a mess, since for the three options below we stop and don't do any of the rest
if fromWhere["rename"] == "1" # Renaming only or could use if whichOne == "Rename"
  renameFolder = renameGUI(srcRename) 
  srcRename = renameFolder["srcSelect"].to_s  + "/" # Name in dialog box which may be different than default
  puts "\n#{lineNum}. Photos in #{srcRename} will be renamed using date and time."
  rename(srcRename, timeZonesFile, timeNowWas)
  # abort # break gives compile error
  abort if (whichDrive == "R") # break doesn't work, but abort seems to
end

# Option for adding GPS coordinates while not moving photos
# if fromWhere["gpsCoords"] == "1" # Renaming only or could use if whichOne == "Rename"
#   srcGpsAdd = gpsCoordsGUI(srcGpsAdd) # Puts up dialog box, sends default file location and retrieves selected file location
#   srcGpsAdd = srcGpsAdd["srcSelect"].to_s  + "/" # Name in dialog box which may be different than default
#   puts "\n#{lineNum}. NOT WORKING YET. Photos in #{srcGpsAdd} will have GPS coordinates added in place."
#   puts "PAY ATTENTION TO YEAR AS NOT SURE MORE THAN ONE YEAR IS INCLUDED IN MY MODULE"
#   puts "#{lineNum} Debugging.\n srcGpsAdd: #{srcGpsAdd} \n folderGPX: #{folderGPX}  \n gpsPhotoPerl: #{gpsPhotoPerl}  \n tzoLoc: #{tzoLoc} added manually. TODO ask for"
#   perlOutput = addCoordinates(srcGpsAdd, folderGPX, gpsPhotoPerl, tzoLoc) # Don't need perlOutput since abort
#   puts "#{lineNum}. Added coordinates to photos in #{srcGpsAdd}\nMultiline perlOutput follows:\n#{perlOutput}"
#   abort # break gives compile error
#   # abort if (whichDrive == "R") # break doesn't work, but abort seems to
# end

# Option for adding location information based on GPS coordinates while not moving photos. An option in the first dialog window, haven't used in long time
if fromWhere["gpsLocation"] == "1"
  srcAddLocation = addLocationGUI(srcAddLocation)  # Puts up dialog box, sends default file location and retrieves selected file location. reusing variable. One above made new temporary variable
  srcAddLocation = srcAddLocation["srcSelect"].to_s  + "/" # Name in dialog box which may be different than default
  puts "\n#{lineNum}. NOT IMPLEMENTED. Photos in #{srcAddLocation} will have location information added based on GPS coordinates in EXIF data without moving the file. NOT IMPLEMENTED."
  puts "#{lineNum}. Need to confirm that the following works. May need to change year of folder for gpx tracks"
  addLocation(srcAddLocation, geoNamesUser)
  abort # break gives compile error
  # abort if (whichDrive == "R") # break doesn't work, but abort seems to
end

lastPhotoReadTextFile = sdCard + "lastPhotoRead.txt"
# if File.exist?(lastPhotoReadTextFile) # If SD card not mounted. TODO logic with else to try again

if whichOne=="SD" # otherwise it's HD, probably should be case for cleaner coding
  # if File.exist?(lastPhotoReadTextFile) # If SD card not mounted. TODO logic with else to try again
  # TODO Put up a dialog to remind to mount the SD card and return to here.
  # read in last filename copied from card previously
  begin
    # Read from SD card
    # lastPhotoReadTextFile = sdCard + "/lastPhotoRead.txt" # But this doesn't work if a new card.
    puts "\n#{lineNum}. lastPhotoReadTextFile: #{lastPhotoReadTextFile}. NEED an error here if card not mounted!!. Have a kludge fix in the next rescue."
    file = File.new(lastPhotoReadTextFile, "r")
    lastPhotoFilename = file.gets # apparently grabbing a return. maybe not the best reading method.
    puts "\n#{lineNum}. lastPhotoFilename: #{lastPhotoFilename.chop}. Value can be changed by user, so this may not be the value used."
    # lastPhotoFilename is 8 characters long (P plus 7 digits) at present.
    # Adding date to this line, so will take first 12 characters (would be cleaner if made the write an array or json and worked with that, but this is the quick and dirty)
    lastPhotoFilename = lastPhotoFilename[0..7]
    puts "#{lineNum}. lastPhotoFilename: #{lastPhotoFilename}. Confirming new method of reading. Should look like line above. Not implemented as haven't found an easy way to write to the beginning of the file."
    file.close
  # rescue Exception => err # Not good to rescue Exception
  rescue => err
    puts "Exception: #{err}. Not critical as value can be entered manually by user.\n"
  end

  begin
    srcSD = srcSDfolder + lastPhotoFilename.chop.slice(1,3) + "_PANA"
  rescue Exception => e
    puts "#{lineNum} +++++++++++++ SD card not available, so will EXIT.++++++++++. Probably selected wrong option."
    exit
  end

# Don't know if this is needed, why not use srcSD directly
  src = srcSD
  prefsPhoto = pPashua2(src,lastPhotoFilename,mylioStaging,archiveFolder) # calling Photo_Handling_Pashua-SD. (Titled: 2. SD card photo downloading options)
  # to get a value use prefsPhoto("theNameInFileNamingEtcPashua.rb"), nothing to do with the name above
  # puts "Prefs as set by pPashua"
  # prefsPhoto.each {|key,value| puts "#{key}:       #{value}"}
else # whichOne=="HD", but what
  src = srcHD
  # puts "#{lineNum}. `srcHD`: #{src}. Does it have a slash?"
  prefsPhoto = pGUI(src, mylioStaging, archiveFolder) # is this only sending values in? 
  # to get a value use prefsPhoto("theNameInFileNamingEtcPashue.rb"), nothing to do with the name above
  # puts "Prefs as set by pGUI"
  # prefsPhoto.each {|key,value| puts "#{key}:       #{value}"}
  src = prefsPhoto["srcSelect"].to_s  + "/"
  # puts "#{lineNum}. src: #{src}. Does it have a slash?"
end # whichOne=="SD"
# else
#   puts "#{lineNum}. SD card not mounted. (=== Some logic so can mount and try again. ===)"
#   abort
# end #SD card mounted

mylioStaging = prefsPhoto["destPhotoP"].to_s + "/" 
# puts "#{lineNum}. mylioStaging: #{mylioStaging} from Pashua" # debugging

archiveFolder = prefsPhoto["destOrig"].to_s + "/"
# Above are true whether SD or from another folder

# But first check that mylioStaging is empty. I'm assuming mylioStaging has been determined at this point
mylioStagingCount = Dir.entries(mylioStaging).count
if mylioStagingCount > 3 # 
  puts "\n#{lineNum}. #{mylioStagingCount} files are in the destination folder"
  # Put up a notice or ask if want to delete them. Or list the first few
end

puts "\n#{lineNum}. Initialization complete. File renaming and copying/moving beginning.\n        Time below is responding to options requests via Pashua if copying an SD card, otherwise the two times will be the same."

timeNowWas = timeStamp(timeNowWas, lineNum)

#  If working from SD card, copy or move files to " Drag Photos HERE Drag Photos HERE" folder, then will process from there.
# puts "#{lineNum}..   src: #{src} \nsrcHD: #{srcHD}"

copySD(src, srcHD, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) if whichOne == "SD"
#  Note that file creation date is the time of copying. May want to fix this. Maybe a mv is a copy and move which is sort of a recreation. 

timeNowWas = timeStamp(timeNowWas, lineNum)

puts "\n#{lineNum}. Photos will now be copied and moved in readiness for renaming, etc."

# COPY AND MOVE and sort jpgs
# Which drive has already been decided. (this note because it hadn't yet if Daguerre wasn't available)

# puts "#{lineNum}. mylioStaging: #{mylioStaging}" # debugging
photosArray = mylioStageAndArchive(srcHD, mylioStaging, tempJpg, archiveFolder, photosArray)
# Now do the same for the jpg files. Going to tempJpg and moving files to same places, except no jpg's will move to tempJpg

# photosArray = mylioStageAndArchive(tempJpg, mylioStaging, tempJpg, archiveFolder, photosArray)
# puts "#{lineNum}. photosArray:" # Arrays seem to get mixed up if put in a {}
# puts photosArray
#  To see how it looks
puts "\n#{lineNum}. photosArray[2]: #{photosArray[2]}. Sample of photosArray. NEEDS to have dateTimeStamp if to be useful, which it doesn't now." # Shows everything
# puts "photosArray[2]: " + photosArray[2] # only the index (3) shows up, not now
puts "#{lineNum}. Next should write photosArray to #{photoArrayFile}"
File.write(photoArrayFile, photosArray) # A list of all the files processed. Saved with script. Work with this later
# unmount card. Test if using the SD
# puts "\n#{lineNum}. fromWhere: #{fromWhere}. whichDrive: #{whichDrive}. whichOne: #{whichOne}"
# whichOne =="SD" ? unmountCard(sdCard) : "" # not working so turned off TODO

# timeNowWas = timeStamp(timeNowWas, lineNum) # moved into line below

puts "\n#{lineNum}. Photos will now be renamed. #{timeNowWas = timeStamp(timeNowWas, lineNum)}"

puts "\n#{lineNum}. Rename [tzoLoc = rename(…)] the photo files with date and an ID for the camera or photographer (except for the paired jpgs in #{tempJpg}). #{timeNowWas}\n"
# tzoLoc = timeZone(fileDateTimeOriginal, timeZonesFile) # Second time this variable name is used, other is in a method
# RENAME Raw
puts "#{lineNum}. mylioStaging: #{mylioStaging}. Renaming photo files with date-time. Failing with this call to rename()" # debugging
tzoLoc = - rename(mylioStaging, timeZonesFile , timeNowWas).to_i # This also calls rename which processes the photos, but need tzoLoc value. Negative because need to subtract offset to get GMT time. E.g., 10 am PST (-8)  is 18 GMT

timeNowWas = timeStamp(timeNowWas, lineNum)
#Rename the jpgs and then move to Latest Download
puts "\n#{lineNum}. Rename the jpgs in #{tempJpg} and then move to #{mylioStaging}. #{timeNowWas = timeStamp(timeNowWas, lineNum)}"
rename(tempJpg, timeZonesFile, timeNowWas)
#  Move the jpgs to mylioStaging (Latest Download)
jpgsMovedCount = 0 # Initializing for debugging puts
Dir.foreach(tempJpg) do |item|
  next if ignoreNonFiles(item) == true
  fn  = tempJpg   + item # sourced from temporary storage for jpgs 
  fnp = mylioStaging + item # new jpg file in Latest Download
  # puts "#{lineNum}.#{jpgsMovedCount += 1}. #{fn} moved to #{fnp}" # dubugging
  FileUtils.move(fn, fnp)
end

timeNowWas = timeStamp(timeNowWas, lineNum)

puts "\n#{lineNum}. Using perl script to add gps coordinates. Will take a while as all the gps files for the year will be processed and then all the photos. -tzoLoc, `i.e.: GMT #{-tzoLoc}"

puts "\n#{lineNum} tzoLoc: #{tzoLoc}. Because GX8 and some other cameras use local time and not GMT as this script was originally written for. All photos must be in same time zone."
# Add GPS coordinates.
perlOutput = addCoordinates(mylioStaging, folderGPX, gpsPhotoPerl, tzoLoc)

timeNowWas = timeStamp(timeNowWas, lineNum)

# Write timeDiff to the photo files
puts "\n#{lineNum}. Write timeDiff to the photo files"
writeTimeDiff(perlOutput)

timeNowWas = timeStamp(timeNowWas, lineNum)
# Parce perlOutput and add maxTimeDiff info to photo files

puts "\n#{lineNum}. All Finished. Note that \"Adding location information to photo files\" is commented out, i.e., geographic descriptions not being added."

# Move to Mylio folder (can't process in this folder or Mylio might import before changes are made)
mylioFolder = iMacMylio # need to generalize this
mylioFolder = "/Volumes/MtnBikerSSD/Mylio_87103a/2022/GX8-2022/"
moveToMylio(mylioStaging, mylioFolder, timeNowWas)

# timeNowWas = timeStamp(timeNowWas, lineNum)
# puts "\n#{lineNum}.-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  - All done"
