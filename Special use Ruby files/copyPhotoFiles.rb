#!/usr/bin/env ruby

# Four lines to comment out to dry run. The last two lines are only about renaming. The first two are more important. Only copying, so original not changed, but it is copying many files potentially

# Got an error running from command line. Works in TextMate

# Requirements
# Ruby
# Three requires below. One is a gem? Others are part of Ruby.
#
# To set up. chruby, ruby-install, TextMate?
# Only tested on my Macs which have all of the above.
# See below about allowing TextMate to have permissions to access 

require 'find'
require 'fileutils'
require 'mini_exiftool'

# on MBA
folder = "/Users/gscar/Pictures/LSB Photos Library.photoslibrary"
folder_to = "/Users/gscar/Documents only on MBA/◊ Pre-trash (MBA)/Photos extraction/photos_copied/"
folder_too_small = "/Users/gscar/Documents only on MBA/◊ Pre-trash (MBA)/Photos extraction/small_photos/"

# on MBP
# folder = "/Users/gscar/Pictures/Photos Library.photoslibrary/"
# folder = "/Users/gscar/Pictures/Photos Library.photoslibrary/originals/0/"
# # If "Operation not permitted @ dir_initialize"  https://stackoverflow.com/questions/58479686/permissionerror-errno-1-operation-not-permitted-after-macos-catalina-update
# # / at end needed for rename module
# folder_to = "/Users/gscar/Documents only on MBP/◊ Pre-trash (MBP)/PhotoExtraction/photos_copied/"
# folder_too_small = "/Users/gscar/Documents only on MBP/◊ Pre-trash (MBP)/PhotoExtraction/too_small/"

file_size_min = 100000 # somewhere around 500 x 500
file_count = 0
files_copied = 0
photo_file_extensions = [".jpg", ".heic", ".JPG", ".jpeg", ".mp4", ".png", ".mov", ".rw2"]
list_copied = ""
list_not_copied = ""
list_too_small = ""
puts "29. Copy photos from #{folder}\n to #{folder_to}\n or if small to #{folder_too_small}\n"

Find.find(folder) do |path|
  file_size = File.size(path)
    # puts "#{path}"
  if File.file?(path) # skipping directories, only processing files in this loop
    file_count += 1
    file_size = File.size(path)     
    if (photo_file_extensions.include? File.extname(path)) && (file_size > file_size_min)      
      # puts "path: #{path}  Photo file and size: #{file_size}"
      list_copied += "#{path}  Photo file and size: #{file_size}\n"
      FileUtils.cp(path, folder_to)  # comment this out to dry run and other folder
      files_copied += 1
    else # Files not copied
      # puts "path: #{path} sized #{file_size} not copied"
      if !photo_file_extensions.include? File.extname(path)
        list_not_copied += "#{path}\n"
      else
        FileUtils.cp(path, folder_too_small)  # comment this out to dry run
        list_too_small += "#{path} sized #{file_size}\n"
      end
    end
  else # directory
    puts "dir:  #{path}. Directory skipped."
  end
end
puts "file_count: #{file_count}"
puts "Count of files copied: #{files_copied}"
puts "\nPhotos copied to #{folder_to}\n"
puts list_copied
puts "End of photo copied to #{folder_to}\n"

puts "\nSmall photos copied to #{folder_too_small}"
puts list_too_small
puts "End of too small to copy to #{folder_to}, but were copied to #{folder_too_small}\n"

puts "\nOther files not copied"
puts list_not_copied
puts "End of not copied list"

def ignoreNonFiles(item) # invisible files or .xmp that shouldn't be processed
  item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon ' or item.slice(0,7) == ".MYLock" or item.slice(-4,4) == ".xmp"
end

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

def fileAnnotate(fn, fileDateTimeOriginalstr)
  # Called from rename
  # writing original filename and dateTimeOrig to the photo file.
  fileEXIF = MiniExiftool.new(fn)
   fileEXIF.instructions = "#{fileDateTimeOriginalstr}" if !fileEXIF.DateTimeStamp # Time zone of photo is GMT #{tzoLoc} unless TS5?" or travel. TODO find out what this field is really for
  # fileEXIF.comment = "Capture date: #{fileDateTimeOriginalstr} UTC. Time zone of photo is GMT #{tzoLoc}. Comment field" # Doesn't show up in Aperture
  # puts "#{lineNum}. fileEXIF.source: #{fileEXIF.source}.original file basename not getting written"
  # puts "#{File.basename(fn)} original filename to be written to EXIF.title"
  fileEXIF.PreservedFileName = "#{File.basename(fn)}" # title ends up as Title above the caption. Source shows up in exiftool as IPTC::Source, but this field does not show up in Preview, but does in Mylio
  # Am I misusing this? I may using it as the TimeZone for photos taken GMT 0 TODO
  # OffsetTimeOriginal	(time zone for DateTimeOriginal) which may or may not be the time zone the photo was taken in TODO
  # TODO write GMT time to
  fileEXIF.save
end # fileAnnotate. writing original filename and dateTimeOrig to the photo file and cleaning up TS5 photos with bad (no) GPS data.

# If want to rename files with datetime. From PhotoName-GPScoord without time shift. 
def rename(src)
  # src is folder_to
  fn = fnp = fnpPrev = "" # must declare variable or they won't be available everywhere in the module
  subSecPrev = subSec = ""
  fileDatePrev = ""
  dupCount = 0
  count    = 1
  seqLetter = %w(a b c d e f ) # used when subsec doesn't exist
  # puts "#{lineNum}. Entered rename and ready to enter foreach. src: #{src}"
  Dir.foreach(src) do |item| # for each photo file
    next if ignoreNonFiles(item) == true # skipping file when true, i.e., not a file
    # puts "#{lineNum}. File skipped because already renamed, i.e., the filename starts with 20xx #{item.start_with?("20")}"
    next if item.start_with?("20") # Skipping files that have already been renamed.
    fn = src + item # long file name
    fileEXIF = MiniExiftool.new(fn) # used several times
    # fileEXIF = Exif::Data.new(fn) # see if can just make this change, probably break something. 2017.01.13 doesn't work with Raw, but developer is working it.
    camModel = fileEXIF.model
    if File.file?(fn) # why is this needed. Do a check above
      # Determine the time and time zone where the photo was taken
      # puts "#{lineNum}.. fn: #{fn}. File.ftype(fn): #{File.ftype(fn)}." #  #{timeNowWas = timeStamp(timeNowWas)}
      fileExt = File.extname(fn).tr(".","").downcase  # needed later for determining if dups at same time. Will be lowercase jpg or rw2 or whatever
      fileExtPrev = ""
      fileDateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
      # puts "#{lineNum}. fileDateTimeOriginal = fileEXIF.dateTimeOriginal: #{fileDateTimeOriginal} of class: #{fileDateTimeOriginal.class}"
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
      if count == 1 | 1*100 # only gets written every 100 files.
        puts "#{lineNum}. panasonicLocation: #{panasonicLocation}l\n"
      end # count
      timeChange =  0 # 3600 *  # setting it outside the loops below and get reset each time through. But can get changed
      # puts "#{lineNum}. camModel: #{camModel}. fileEXIF.OffsetTimeOriginal: #{fileEXIF.OffsetTimeOriginal}"
      if camModel ==  "MISC" # MISC is for photos without fileDateTimeOriginal, e.g., movies
        # timeChange = 0
      puts "#{lineNum}.. fileDateTimeOriginal #{fileDateTimeOriginal}. timeChange: #{timeChange} for #{camModel} meaning movies"
      elsif camModel == "iPhone X"  # DateTimeOriginal is in local time
        # timeChange = 0
        fileEXIF.OffsetTimeOriginal = "GMT" # ??
       end # if camModel
      fileEXIF.save # only set OffsetTimeOriginal, but did do some reading.

      fileDate = fileDateTimeOriginal + timeChange.to_i # date in local time photo was taken. No idea why have to change this to i, but was nil class even though zero  
      fileDateTimeOriginalstr = fileDateTimeOriginal.to_s[0..-6]

      oneBack = fileDate == fileDatePrev && fileExt != fileExtPrev # at the moment this is meaningless because all of tne type
      if oneBack # at the moment only handles two in the same second
        dupCount += 1
        if subSecExists # mainly GX8. and maybe iPhone bursts
          fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  subSec + userCamCode(fn) # this doesn't happen for the first one in the same second.
           if dupCount == 1
            # Can use old fileDate because it's the same and userCamCode. 
            fnp = src + fileDate.strftime("%Y.%m.%d-%H.%M.%S") + subSecPrev + userCamCode(fn)+  File.extname(fn).downcase
               File.rename(fnpPrev,fnp)
          end # if dup count
        else # photos without subsecs, pre GX8
          fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  seqLetter[dupCount] + userCamCode(fn)
          puts "#{lineNum}. fn: #{fn} in 'if oneBack'.     fileBaseName: #{fileBaseName}."
        end # subSecExists
      else # normal condition that this photo is at a different time than previous photo
        dupCount = 0 # resets dupCount after having a group of photos in the same second
        fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S")  + userCamCode(fn)
      end # if oneBack

      fileDatePrev = fileDate
      fileExtPrev = fileExt
      fileAnnotate(fn, fileDateTimeOriginalstr) # was passing fileEXIF, but saving wasn't happening, so reopen in the module?
      fnp = fnpPrev = src + fileBaseName + File.extname(fn).downcase
      subSecPrev = subSec.to_s
      File.rename(fn,fnp)
      count += 1
     else
      puts "#{lineNum}. CHECKING why `if File.file?(fn)` is needed. File.file?(fn): #{File.file?(fn)} for fn: #{fn}"
    end # 3. if File.file?(fn)
    
  end # 2. Dir.foreach(src)
  puts "Photo files in #{src} renamed with date-time-etc"
end # rename ing photo files in the downloads folder and writing in original time.

puts "287. Now rename files with date-time-etc"
rename(folder_to)
rename(folder_too_small)