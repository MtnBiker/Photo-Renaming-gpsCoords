#!/usr/bin/env ruby
# Fixing files recovered from a corrupted SD card. 
# EXIF info was correct, but Apple Info wasn't. I hope can change created and modified date to EXIF created date

require 'rubygems' # # Needed by rbosa, mini_exiftool, and maybe by appscript. Not needed if correct path set somewhere.
require 'mini_exiftool' # A wrapper for the Perl ExifTool, Confirmed version exiftool -ver >> 11.10

src = "/Users/gscar/Documents/◊ Pre-trash/SD card recovery Sept 2018/scriptTestingFrom/"
# src = "/Users/gscar/Documents/◊ Pre-trash/SD card recovery Sept 2018/scriptTestingTimeChange/" # for checking changing of creation time
fixedFiles = "/Users/gscar/Documents/◊ Pre-trash/SD card recovery Sept 2018/fixedFiles/"
userCamCode = ".gs.W" # gs for photographer. W for *w*aterproof Panasonic Lumix DMC-TS5

def ignoreNonFiles(item) # invisible files that shouldn't be processed
  item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon '
  # This is true when it should not be processed i.e. next if ignoreNonFiles(item) == true
end

def fileAnnotate(fn, fileEXIF, fileDateUTCstr, tzoLoc)  # writing original filename and dateTimeOrig to the photo file.
  # writing original filename and dateTimeOrig to the photo file.
  # ---- XMP-photoshop: Instructions  May not need, but it does show up if look at all EXIF, but not sure can see it in Aperture
  # SEEMS SLOPPY THAT I'M OPENING THE FILE ELSEWHERE AND SAVING IT HERE
  if fileEXIF.source.to_s.length < 2 # if exists then don't write. If avoid rewriting, then can eliminate this test. Was a test on comment, but not sure what that was and it wasn't working.
     fileEXIF.instructions = "#{fileDateUTCstr} UTC. Time zone of photo is GMT #{tzoLoc} unless TS5?"

    fileEXIF.source = "#{File.basename(fn)}"
    fileEXIF.TimeZoneOffset = tzoLoc    
    fileEXIF.save
  end
end # fileAnnotate. writing original filename and dateTimeOrig to the photo file and cleaning up TS5 photos with bad (no) GPS data.

fileDatePrev = ""
dupCount = 0
count    = 0
seqLetter = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z aa bb cc) 
Dir.foreach(src) do |item|
  next if ignoreNonFiles(item) == true # skipping file when true
  fn = src + item
  fileEXIF = MiniExiftool.new(fn) # used several times
  if File.file?(fn)
    # Determine the time and time zone where the photo was taken
    # puts "315.. fn: #{fn}. File.ftype(fn): #{File.ftype(fn)}." #  #{timeNowWas = timeStamp(timeNowWas)}
    fileDateUTC = fileEXIF.dateTimeOriginal # class time, but adds the local time zone to the result although it is really UTC (or whatever zone my camera is set for. For TS5, the time date is accurate with time zone)
     fileDate = fileDateUTC # ???
  
    fileDateUTCstr = fileDateUTC.to_s[0..-6]

    filePrev = fn
     oneBack = fileDate == fileDatePrev # true if previous file at the same time calculated in local time
    puts "#{fileDate} == #{fileDatePrev}. oneBack: #{oneBack}."
    if oneBack
      dupCount =+ 1
      fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  seqLetter[dupCount] + userCamCode           
    else # normal condition that this photo is at a different time than previous photo
      dupCount = 0 # resets dupCount after having a group of photos in the same second
 
      fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S")  + userCamCode
     end # if oneBack
    fileDatePrev = fileDate
    fileBaseNamePrev = fileBaseName
 
    # File renaming and/or moving happens here
    
    # Testing
    puts "fn: #{fn}, fileEXIF: #{fileEXIF}, fileDateUTCstr: #{fileDateUTCstr}"
     fnp = fixedFiles + fileBaseName + File.extname(fn).downcase
    File.rename(fn,fnp)
    
    #Now trying to change mod and access time. This is supposed to change creation time since the creation time has to be before the mod time, and all the files fit this criteria since the creation date shows as the day the files were recovered.
    File.utime(fileDateUTC ,fileDateUTC, fnp) # time may not be the right format
    count += 1
  end # 3. if File
end # 2. Find  
