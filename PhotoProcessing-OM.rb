#!/usr/bin/env ruby
# ruby "/Volumes/Macintosh HD/Users/gscar/Documents/Ruby/Photo handling/PhotoName-Class.rb"

# Written for OM-1. Copied and modified from PhotoName-GPScoord-macOSphotos.rb: #{rb}. 
# See Outline of script.txt for implementation

require 'fileutils'
include FileUtils
require 'find'
# require 'yaml'
require "time"
require 'irb' # binding.irb where error checking is desired
require 'mini_exiftool' # `gem install mini_exiftool` have to update for 

# Some toggles for testing and development, will 
putsArray = true # `true` to print the array in the console
production = false # false uses /testingDev files. True is for real
showPuts = false # true showing debugging puts. Search for `if showPuts ==`
addPreservedNameForDebugging = false # to put something in front of filename to make sure not overwrittten Good for other DEBUGGING
# fileDateStr = "#{photo.preservedFileName}.#{fileDateStr}"


HOME = "/Users/gscar/"
thisScript = "#{File.dirname(__FILE__)}/" # needed because the Pashua script calling a file seemed to need the directory. 
# thisScript = File.dirname(__FILE__) +"/" # needed because the Pashua script calling a file seemed to need the directory.
photosRenamedTo = thisScript + "currentData/photosRenamedTo.txt"

# use to select file locations on Mini (Model Identifier: Mac14,12) and MBA
model_identifier = `system_profiler SPHardwareDataType | grep "Model Identifier"`.split(':').last.strip
# puts "Model Identifier: #{model_identifier}"


if production # set above
	unneededBrackets = downloadsFolders + "Unneeded brackets/" # on Daguerre
	srcHD       = downloadsFolders + " Drag Photos HERE/" # 
	srcHD = "testingDev/incomingTestPhotos"
	mylioStaging = downloadsFolders + "Latest Processed photos-Import to Mylio/" #  These are relabeled and GPSed files. Will be moved to Mylio after processing.		
else # development or testing	
	unneededBrackets = thisScript + "/testingDev/unneededBrackets" # DEV rename to unneededBrackets, but is this the right name
	# temp src until determine using. Full path needed to run from arbitrary place in iTerm. Relative works in Nova
	# Need to change to srcHD
	src = thisScript + "/testingDev/incomingTestPhotos/" # Stacked w/ and w/o a stacked image, HHHR, THR, 
	# src = "/Volumes/Daguerre/_Download folder/_imported-archive/OM-1/OB[2024.11]-OM/" # 308 photos
	# src = "/Volumes/Daguerre/_Download folder/_imported-archive/OM-1/OA[2024.10]-OM/" # 476 photos
	# src = thisScript + "/testingDev/singleTestPhoto"	
	mylioStaging = thisScript + "/testingDev/staging" # DEV	
end
puts "\n#{__LINE__}. mylioStaging: #{mylioStaging}."

# Not planning to use initially or at all
# timeZonesFile = thisScript + "currentData/Greg camera time zones.yml"

# locations of folderGPX, 
case model_identifier
when "Mac14,12" # Mac mini M2 Pro
	folderGPX = HOME + "Documents/GPS-Maps-docs/  GPX daily logs/2024 GPX logs/" # Could make it smarter, so it knows which year it is. Massaged contains gpx files from all locations whereas Downloads doesn't.
when "MacBookAir10,1" # 2020 MBA M1 13"
	folderGPX = "/Users/gscar/Library/Mobile Documents/com~apple~CloudDocs/Documents/GPS-Maps-docs/  GPX daily logs/2024 GPX logs"
else
	puts "#{__LINE__}. Something in the GUI to select the location of the GPX files"	
end # case model_identifer

puts "#{__LINE__}. Must manually set folderGPX for GPX file folders. Particularly important at start of new year AND if working on photos not in current year.\n       Using: #{folderGPX}\n"

class Photo
	
	@@count = 0
	
	attr_accessor :id, :fn, :fileName, :fileExt, :camModel, :fileType, :stackedImage, :driveMode, :specialMode, :afPointDetails, :subjectTrackingMode, :createDate, :sameSecond, :dateTimeOriginal, :offsetTimeOriginal, :preservedFileName
	# order by need for sorting and dealing with

  def initialize(id, fn, fileName, fileExt, camModel, fileType, stackedImage, driveMode, specialMode, afPointDetails, subjectTrackingMode, createDate, sameSecond, dateTimeOriginal, offsetTimeOriginal, preservedFileName)
		
# The counting needs work if I need it, where did I get it from
		# Every time a Photo (or a subclass of Photo) is instantiated,
		# we increment the @@count class variable to keep track of how
		# many photos have been created.
		# self.class.increment_count # Invoke the method.
	
		# def self.increment_count
		# 	@@count += 1
		# end
		# 
		@id = id
		@fn = fn
		@fileName = fileName # same as preservedFileName, but fileName is not viewable in Mylio
		@camModel = camModel
		@fileExt = fileExt
		@fileType = fileType
		@stackedImage = stackedImage
		@driveMode = driveMode
		@specialMode = specialMode
		@afPointDetails = afPointDetails
		@subjectTrackingMode = subjectTrackingMode
		@createDate = createDate
		@sameSecond = sameSecond
		@dateTimeOriginal = dateTimeOriginal,
		@offsetTimeOriginal = offsetTimeOriginal
		@preservedFileName = preservedFileName
  end
		
end # class photo

# MODULES

def copy_with_mac_renaming(fn, fnp)
	# Using macOS to do the renaming, but so far not working, From ChatGPT
	# Escape file paths for AppleScript
	escaped_fn = fn.gsub("'", "\\'")
	escaped_fnp = fnp.gsub("'", "\\'")

	# AppleScript command
	applescript = <<~APPLESCRIPT
		on run argv
				set sourceFilePath to POSIX file (item 1 of argv)
				set destinationDirPath to POSIX file (item 2 of argv)

				tell application "Finder"
						duplicate file sourceFilePath to folder destinationDirPath
				end tell
		end run
	APPLESCRIPT

	# Execute the AppleScript with osascript
	script_result = `osascript -e '#{applescript}' '#{escaped_fn}' '#{escaped_fnp}'`

	# Check for errors
	if $?.success?
		puts "File copied successfully!"
	else
		puts "Error during file copy: #{script_result}"
	end
end # copy_with_mac_renaming

#
def filesToIgnore(item) # invisible files or .xmp that shouldn't be processed
	item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon ' or item.slice(0,7) == ".MYLock" or item.slice(-4,4) == ".xmp"
end

def number_to_letter(number)
	# Since it's fairly easy to label photos in same seconds with numbers in the photo.array, but numbers are messier in the basename
	# Ensure the number is within the range of 1 to 26
	if number.between?(1, 26)
		# Convert the number to the corresponding letter (1 = 'a', 2 = 'b', ..., 26 = 'z')
		('a'.ord + number - 1).chr
	else
		# nil # Return nil for numbers outside the range
		"." + number.to_s
	end
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

def exiftoolAddCoordinates(photoFolder, folderGPX)
	# Remember writing a command line command which uses exiftool
	# --timeoffset seconds     Camera time + seconds = GMT. No default.  
	# maxTimeDiff = 50000 # seconds, default 120, but I changed it 2011.07.26 to allow for pictures taken at night but GPS off. Distance still has to be reasonable, that is the GPS had to be at the same place in the morning as the night before as set by the variable below
		
	# photoFolder is where the photos are that are going to have gps coordinates added. A temporary location. Usually called mylioStaging is the overall script
	# folderGPX is where the gpx tracks are
	
	puts "#{__LINE__}.All photos must be same camera and time zone or photos may be mislabeled and geo-located." 
	 
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
	puts "\n#{__LINE__}. Any existing geotags will be overwritten until I can figure out how to add -if 'not $gpslatitude' gpxLogs: #{gpxLogs}. photoFolder; #{photoFolder})"
	exiftoolGps = system("exiftool", "-geotag",  "#{gpxLogs}", "#{photoFolder}", "-overwrite_original") # will overwrite existing tags
	puts "\n#{__LINE__}. exiftool report above #{Time.now.strftime("%I:%M:%S %p")}"
	# puts "\n#{__LINE__}======== End of exiftool geotag ==========  #{Time.now.strftime("%I:%M:%S %p")}\n"
	# return exiftoolGps # return is true unless want to get the notes, but they show in script results
end # exiftoolAddCoordinates
	
# change name to something like sameSeconds
def sameSecondTrue(src, fn, fnp, fnpPrev, fileDateStr, driveMode, sameSec, camModel, userCamCode)
	# Some of these fields may not be needed, I was fighting the wrong problem and may have added some that aren't needed
	puts "\n#{__LINE__}. fn: #{fn}. fnp: #{fnp}. fileDateStr: #{fileDateStr}. driveMode: #{driveMode}.  sameSec: #{sameSec}. in sameSecondTrue(). DEBUG"
	# sameSec += 1
	
	# This should be screened out before here now.
	# Getting sequence no./shot no. for OM-1. DriveMode is "Single Shot; Electronic shutter" for normal photos
	
	# Commented out 14 lines below that don't seem to be doing anything needed FIXME delete
	# unless driveMode.nil? || driveMode.empty? # opposite of if, therefore if driveMode is not empty
	# 	match = driveMode.match(/Shot (\d{1,3})/)
	# 	shot_no = match[1].to_i if match
	# 	shootingMode = driveMode.split(',')[0]
	# 	puts "\n#{__LINE__}. fn: #{fn}. driveMode: #{driveMode}. shot_no: #{shot_no}. shootingMode: #{shootingMode}. fileDateStr: #{fileDateStr}. DEBUG"
	# end
	
	# if shot_no.to_i > 0 # photos without subsecs. OM-1 but with shot number.
	# 	# Getting sequence no. for OM-1. DriveMode is "Single Shot; Electronic shutter" for normal photos
	# 		 # puts shot_no
	# 	# End getting seqence no
	# 	# fileBaseName = fileDateStr + "-" + shot_no.to_s + userCamCode
	# 	fileBaseName = "#{fileDateStr}-#{shot_no.to_s}#{userCamCode}"
	# 	puts "#{__LINE__}. fn: #{fn} in 'if oneBack'. fileBaseName: #{fileBaseName}. fileDateStr: #{fileDateStr}. shot_no: #{shot_no}. userCamCode(fn): #{userCamCode}. NEVER GEY TO HERE" 
	# else # photos without subsecs, pre GX8 and other OM-1 in same second
		# puts "#{__LINE__}. fn: #{fn} in 'if oneBack'. fileDateStr: #{fileDateStr}. sameSec: #{sameSec}. userCamCode(fn): #{userCamCode(fn)}. debug"
			
		# FIXME. I think the next 12 or so lines are not being used.
		# driveMode = fileEXIF.DriveMode # '-DriveMode : Continuous Shooting, Shot 12; Electronic shutter'
		# puts "#{__LINE__}. driveMode: #{driveMode}. driveMode.class: #{driveMode.class} for . " # error if?
		# if driveMode.class == "NilClass" # FIXME delete in time
			# fileBaseName = fileDateStr + "-" + sameSec.to_s + userCamCode
			fileBaseName = "#{fileDateStr}-#{sameSec.to_s}#{userCamCode}"
			puts "#{__LINE__} #{fileBaseName} has sameSec" # debug 
		# elsif driveMode.length > 0
			match = driveMode.match(/Shot (\d{1,3})/)
			if match
				# shot_no = match[1].to_i
				puts "#{__LINE__} #{fileDateStr} is shot that contributed to a Focus Stacked image" # debug 
			else 
				shot_no = "ss" # Was FS in camera Focus Stacked image, Now ss for same second FIXME. Maybe even just an extra period
				puts "\n#{__LINE__} #{fileDateStr} Currently picking up images in the same second" # debug
				# 125 2024.12.15-16.03.29 an in camera Focus Stacked image and the contributing images should not be sent to Mylio. Currently picking up images in the same second
			end
			
			# Using sequence number # old uglier way. Can delete in time
			# fileBaseName = "#{fileDateStr}-#{shot_no}#{sameSec.to_s}#{userCamCode}"
			
			# alphabetic sequence of same seceond
			fileBaseName = "#{fileDateStr}#{number_to_letter(sameSec)}#{userCamCode}"
			
			# fileBaseName = fileDateStr + "-" + sameSec.to_s + ".FS" + userCamCode(fn) # for an in camera Focus Stacked image
			
			# Five lines below old cruft
		# else
		# 	puts "#{__LINE__}. driveMode: #{driveMode}. driveMode.class: #{driveMode.class}. NEVER GET TO HERE?" 
		# 	# fileBaseName = fileDateStr + "-" + sameSec.to_s  + userCamCode
		# 	fileBaseName = "#{fileDateStr}-#{sameSec.to_s}#{userCamCode}"
		# end
		
		puts "#{__LINE__}. fn: #{fn} in 'if sameSec'. fileBaseName: #{fileBaseName}."
	# end # subSecExists
	return fileBaseName
end # sameSecondTrue

# Add original file name, rename with coding
def renamePhotoFiles(photo_array, src, timeNowWas, photosRenamedTo, unneededBrackets, showPuts, addPreservedNameForDebugging)
	# Uphoto_array of all the photos bringing in from folder. Read fields needed to process photos
	
	# src is mylioStaging folder ??
	# timeZonesFile is my log of which time zones I was in when
	# timeNowWas used for timing various parts of the script.
	# puts "\n#{__LINE__}. Just entered renamePhotoFiles. timeZonesFile #{timeZonesFile}.  #{timeNowWas}\n" #  src: #{src}. an object? 
	puts "\n#{__LINE__}. Just entered renamePhotoFiles. #{timeNowWas}\n"
	# Until 2017, this assumed camera on UTC, but doesn't work well for cameras with a GPS or set to local time
	# So have to ascertain what time zone the camera is set to by other means in this script, none of them foolproof
	# 60 minutes for ~1000 photos to rename TODO ie, very slow
	fn = fnp = fnpPrev = "" # must declare variable or they won't be available everywhere in the module
	# subSecPrev = subSec = ""
	fileDatePrev = ""
	dupCount = 0
	count    = 1
	countDev = 0
	tzoLoc = ""
	camModel = ""
	userCamCode = ".gs.O." # go back to older version of this if want to determine it
	# Have to re-establish the field names and class since the array doesn't carry the class (a db might have been better)
	unneededBracketedFiles = [] # ~line 781
	stackedImageBoolean = false # Needed for first time through the array.each

	# photo_array.each_with_index do |photo, index| if need index number
	# puts "\n#{__LINE__}. photo_array: #{photo_array}\n"
	puts "\n#{__LINE__}. Entering	`photo_array.reverse.each do |photo|` in renamePhotoFiles(\n" 
	photo_array.reverse.each do |photo| # reverse so no about Stacked Images?
		fn = photo.fn # file_name
		fileName = photo.fileName # this fileName is Ruby basename FIXME
		# puts "\n#{__LINE__}. fn: #{fn}." 
		dateTimeOriginal = photo.dateTimeOriginal
		# puts "\n#{__LINE__}. preservedFileName: #{photo.preservedFileName}.	dateTimeOriginal: #{dateTimeOriginal}. " # sorting out what I was trying to do
		fileDate = dateTimeOriginal # why not createDate? mov?
		# puts "\n#{__LINE__}. fileDate: #{fileDate}. fileDate.class: #{fileDate.class}." #  fileDate: [2024-10-18 10:52:30 -0700, "-07:00"]. fileDate.class: Array. DEV
		fileDateStr = Time.parse(fileDate.to_s).to_s[0..-7].gsub(/-/, '.').gsub(' ', '-').gsub(/:/, '.') # to_s twice? FIXME then chop off time_zone, then change spaces, dashes, and colons to what I want
		# puts "\n#{__LINE__}. fileDateStr: #{fileDateStr}. But want to look like this `2024.10.30-16.28.54`"
		# fileDateStr = "#{count}.#{fileDateStr}" # trying to figure out which files are disappearing DEV
		
		# Uncomment to add old basename to basename for output file. Great for DEBUGGING
		fileDateStr = "#{photo.preservedFileName}.#{fileDateStr}" if addPreservedNameForDebugging == true # if true, trying to figure out which files are disappearing or to make it easier to see preservedFileName DEV
			
		# dateTimeOriginalstr = dateTimeOriginal.to_s[0..-10]		
		# puts "#{__LINE__}. dateTimeOriginalstr: #{dateTimeOriginalstr}.  dateTimeOriginal: #{dateTimeOriginal}. \n Do I need both of these FIXME" 
				# puts "\n#{__LINE__}. fn: #{fn}\n"
				
		# For photos in same second, but not bracketing (can check by shot no.)
		fileExt = photo.fileExt # but established from macOS, not from OM EXIF
		fileExtPrev = ""
		sameSecond = photo.sameSecond
			
		# Change OM .ORI to .ORI.ORF so Apple apps and others can see them. Can't do before fileEXIF.save because fn is "redefined". Hi-Res creates an .ORI
		# Focus stacked first image gets renamed somewhere else and loses the .ori at line 555?
		# But it does get the .ORI.ORF but then gets changed.
		#  BUT messes as files get different basenanes. Others get HiRes and can't name this with HiRes. Happening without this 
		# if fileExt == "ori"
		# 	f_rename = fn + ".ORF"
		# 	fn_orig = File.new(fn)
		# 	# puts "fn.class: #{fn.class}"
		# 	# puts "\n#{__LINE__}. #{fn_orig} (fn_orig)to\n#{f_rename} (fn)about to happen"
		# 	File.rename(fn_orig, f_rename)
		# 	fn = f_rename # since reuse fn
		# 	# puts "#{__LINE__}. Rename happened and now fn is #{fn}." 
		# end 

		# Add  1. If focused-stacked (stackedImage), get count and confirm next x are Focus Bracketing and set aside and mark as brackets
		stackedImage = photo.stackedImage
		driveMode = photo.driveMode # how long does this take? If don't need at highest level check later
		driveModeFirst = driveModeSemiColon = shootingMode = driveMode.split(';')[0] if !driveMode.nil? #  Change driveModeFb to this. nil needed or errors FIXME too many names
		# stackedImageBoolean = false # declared below and would be wrong here
		driveModeFb = driveModeComma = driveMode.split(',')[0] if !driveMode.nil? # driveModeFirst separates on semi-colon, so different results.
		
		# puts "#{__LINE__}. driveModeFirst: #{driveModeFirst}. fileName: #{fileName}. " # Continuous Shooting, Shot 1. But some have a semi-colon separator
		# puts "#{__LINE__}. driveModeFb:    #{driveModeFb}." # Continuous Shooting.

		
		# High resolution can either be Tripod or Hand Held. I doubt these are being used anymore since started using `case` below FIXME
		hiResTripodBoolean = false
		hiResHandheldBoolean = false
		
		puts "#######################################"
		puts "\n#{count}. About to start choices for #{fn}."
		puts "#{__LINE__}. fileName: #{fileName}. fileExt: #{fileExt}. stackedImage: #{stackedImage}.  driveMode: #{driveMode}."
		
		# oneBack = fileDate == fileDatePrev && fileExt != fileExtPrev # at the moment this is meaningless because all of one type?
		# puts "\n#{__LINE__}. oneBack: #{oneBack}.  fileDate: #{fileDate}.  fileDatePrev: #{fileDatePrev}." DEV to see if test is working
		# if oneBack
		# 	puts "\n#{__LINE__}. fileName: #{fileName}. oneBack: #{oneBack}. driveModeFirst: #{driveModeFirst}."
		# 	puts "fileDate: #{fileDate}.  fileDatePrev: #{fileDatePrev}. fnpPrev: #{fnpPrev}."
		# end

		# Maybe handle .mov as special case outside of everything else and handle everything else below
		if fileExt == "mov"
			fileBaseName = "#{fileDateStr}#{userCamCode}." # extra period JIC Debug
			puts "\n#{__LINE__}. fileExt: #{fileExt}.  fileBaseName: #{fileBaseName}. Supposedly handling .mov outside of `case` below. But at the moment not getting renamed and moved. count doesn't advance" #
		end
		
		unless stackedImage.nil? # nil for .mov which is covered above. Everything else is supposed to be covered here
		
			case
			when stackedImage[0..12].to_s == "Focus-stacked" # Focus-stacked (15 images)
				# `Focus-stacked (15 images)`. there is a space after the final digit, so either 1 or 2 digits.
				bracketCount = stackedImage[15..16] 
				# puts "\n#{__LINE__}. #{fn} is a successfully stacked images with #{bracketCount} brackets.\n Now put aside next #{bracketCount} images and rename as brackets"
				fileBaseName = "#{fileDateStr}.FS#{userCamCode}" # Inconsistent naming FIXME? could be _STK_
				stackedImageBoolean = true
				puts "\n#{__LINE__}. fileBaseName: #{fileBaseName}. Focus-stacked . stackedImageBoolean: #{stackedImageBoolean}." if showPuts == true
			
			when stackedImage[0..5].to_s == "Tripod" #  Tripod high resolution
				hiResTripodBoolean = true
				fileBaseName = "#{fileDateStr}.HiResTripod#{userCamCode}" # period or -
				puts "\n#{__LINE__}. fileBaseName: #{fileBaseName}. Tripod" if showPuts == true
						
			when stackedImage[0..24].to_s == "Hand-held high resolution" # Hand-held high resolution
				hiResHandheldBoolean = true
				fileBaseName = "#{fileDateStr}HiResHand#{userCamCode}"
				puts "\n#{__LINE__}. fileBaseName: #{fileBaseName}.Hand-held high resolution" if showPuts == true
				
			when driveModeComma.to_s == "Focus Bracketing" # && !driveMode.nil? redundant driveModeFirst doesn't work
			# FIXME get rid of match as for Continuous Shooting done?
				# match = driveMode.match(/(\d{1,3})/) # Getting shot no. from `Focus Bracketing,  Shot _`
				# # shot_no = match[1].to_i # if match # has to be a match in this loop, so maybe don't need the if
				# shot_no = match[1]
				shot_no = driveMode.match(/(\d{1,3})/)[1]
				# 2024.10.30-16.28.54_08bkt.gs.O.jpg
				# stackBracket = "_" + shot_no.to_s.rjust(2, '0') + "bkt" # trying to tighten name compared to above
				# Label differently if there is a stacked image
				puts "\n#{__LINE__}. stackedImageBoolean: #{stackedImageBoolean}." if showPuts == true
				if stackedImageBoolean
					# fileBaseName = "#{fileDateStr}_#{shot_no}bkt#{userCamCode}" # could be dash instead of underscore
					fileBaseName = "#{fileDateStr}.Bkt-#{shot_no}#{userCamCode}" # yet another format
					puts "\n#{__LINE__}. fileBaseName: #{fileBaseName}. Working through bracketed images for which a stack exists" if showPuts == true
					stackedImageBoolean = false if shot_no == "1" && fileExt == fileExtPrev # reset after last stacked image, but need to check if a jpg orf pair, although this may not work
					puts "\n{__LINE__}. fileBaseName: #{fileBaseName}. Focus Bracketing" if showPuts == true
				else
					fileBaseName = "#{fileDateStr}.Bkt-noStack-#{shot_no}#{userCamCode}" # could be dash instead of underscore
					puts "\n#{__LINE__}. fileBaseName: #{fileBaseName}. Working through bracketed images for which NO stack exists"  if showPuts == true
				end # if stackedImageBoolean in 
				
			when driveModeFirst == "Single Shot" # Can be manual images in same second
				# if sameSecond # the photo is in the same second as the next or preceding photo and needs to be named accordingly by indexing dupCount NO, indexing done when creating photo_array
				if sameSecond > 0
					# dupCount += 1
					dupCount = sameSecond # FIXME rename
					puts "\n#{__LINE__}. fileBaseName: #{fileBaseName}. sameSecond: #{sameSecond}. Entered case sameSecond in Single Shot"
					fileBaseName = sameSecondTrue(src, fn, fnp, fnpPrev, fileDateStr, driveMode, sameSecond, camModel, userCamCode)
					puts "\n#{__LINE__}. fileBaseName: #{fileBaseName}. sameSecond: #{sameSecond}. Entered case sameSecond in Single Shot"
				else
					fileBaseName = "#{fileDateStr}.SS#{userCamCode}" # DEV SS until sort out what all the cases are
					puts "\n#{__LINE__}. fileBaseName: #{fileBaseName}, driveMode: #{driveMode}."
				end

			# Continuous shooting which may (assuming it is for now) be a proxy for ProCapture. `Drive Mode: Continuous Shooting, Shot 7; Electronic shutter`
			when driveModeComma == "Continuous Shooting"
				shot_no = driveMode.match(/(\d{1,3})/)[1]
				fileBaseName = "#{fileDateStr}.ProCap-#{shot_no}#{userCamCode}" # putting shot_no after which
			# The above are OK if in the same second since will get shot-no or the three immediately above, they won't be in same second since takes too long
				puts "\n#{__LINE__}. fileBaseName: #{fileBaseName}. Continuous Shooting" if showPuts == true
				
			# But must check for photos in same second. This should be picked up or handled above but JIC
			when sameSecond > 0
				dupCount += 1
				puts "\n#{__LINE__}. fileBaseName: #{fileBaseName}. sameSecond: #{sameSecond}. Entered case oneBack"			
				fileBaseName = sameSecondTrue(src, fn, fnp, fnpPrev, fileDateStr, driveMode, dupCount, camModel, userCamCode)
			else
				fileBaseName = "#{fileDateStr}#{userCamCode}"
				countDev += 1
				puts "#{__LINE__}.  countDev: #{countDev}. sameSecond: #{sameSecond}. NOT handled by any cases above.  fileName: #{fileName}. fileExt: #{fileExt}. stackedImage: #{stackedImage}.  driveMode: #{driveMode} "

			end # case
		end	# unless
		
		# specialMode = photo.specialMode # Initially no use for specialMode, but will carry for a while FIXME
		
		# match, shot_no = "" # FIXME is this being used 2024.12.20 commented out
		
		fileDatePrev = fileDate
		fileExtPrev = fileExt
		# fileBaseNamePrev = fileBaseName
		# fnp = fnpPrev = src + "/" + fileBaseName + fileExt.downcase
		
		fnp = fnpPrev  = "#{src}\/#{fileBaseName}#{fileExt.downcase}"
		# puts "\n#{__LINE__}. fnp: #{fnp}." 
		# fnp = "Placeholder for DEV"
		# puts "Place holder to make the script work. where did the unless come from"
    puts "\n#{__LINE__}. fn: #{fn}.\nfnp (fnpPrev): #{fnp}" #  fn.class: #{fn.class} DEV
		# puts "\n#{__LINE__}. fn exists: #{File.file?(fn)}. fnp exists: #{File.file?(fnp)} of course not yet." # DEV
		
		# Ensure destination directory exists DEV, because wiping this out in DEV
		destination_dir = File.dirname(fnp)
		FileUtils.mkdir_p(destination_dir)
	
		File.rename(fn,fnp) ## Will replace files if duplicate names which may happen if 
		# copy_with_mac_renaming(fn, fnp) # Trying to avoid replacing files with same name # Error during file copy: OR stalls
		# Add the processed file to the array so can move unneeded bracket files below
		# unneededBracketedFiles << fnp

		count += 1
		# else
		# 	# puts "#{__LINE__}. CHECKING why `if File.file?(fn)` is needed. File.file?(fn): #{File.file?(fn)} for fn: #{fn}"
		# end # 3. if File.file?(fn)
		# puts "#{__LINE__}. Got to here. tzoLoc: #{tzoLoc}"
		
	end # 2. Dir.each_child(src)
	# puts "#{__LINE__}.  A log of photo file renaming is at #{photoRenamed}. For debugging uncomment the line about 3 lines below to get the list in the running log."
	# tzoLoc the time zone the picture was taken in,
	{tzoLoc: tzoLoc, camModel: camModel} #return
end # rename  photo files in the downloads folder and writing in original time.

#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+#+
###### Beginning of actions ###############
# 1. Establish Array.photos
# 2. Rename which may need Array.photos
# 3. Sort and move

if production
else # moving files around for testing
	puts "\n#{__LINE__}. Copy 'virgin' photos to simulated incoming folder. Adding EXIF in place so need virgin to start. Delete /testPhotos and /incomingTestPhotos so folders empty to start DEV\n"	
	testPhotos = 'testingDev/incomingTestPhotos' # equivalent to  Drag Photos HERE except wouldn't wipe that folder	
	FileUtils.rm_rf(testPhotos) # clear out incoming in case some left DEV
	FileUtils.rm_rf(mylioStaging) # clear out photos from previous run DEV
	# puts value.x # created an error here so script would stop and I could check that folder was deleted and it was
	
	# For DEV to have sample files to test with. Only one selected below
	# which folder for sample virgin photos
	virgin_photos = "testingDev/virginOMcopy2incoming" # 122 photos
	# virgin_photos = "testingDev/singleTestPhoto" # one photo 
	FileUtils.cp_r(virgin_photos, testPhotos, preserve: true, remove_destination: true ) # preserve to keep timestamp (may not be neccessary). cp_r is for directory. This directory has a currated batch of photos
	# puts "\n#{__LINE__}. Not using full test stack of photos" 
	# FileUtils.cp_r('testingDev/bracketStackTestPhotos', testPhotos, preserve: true, remove_destination: true ) # just a stack for DEV test
end # if production 

lineNum = "#{__LINE__}"
timeNowWas = timeStamp(Time.now, lineNum)
id = 0
photo_array = []
lastPhotoFilename = "OB305994" # use later as starting point
createDatePrev = Time.now # impossible that first photo processes will in comflict, but need an intial value
photo_id_prev = "" # so defined for first round
sameSecond = 1
fileExtPrev = ""

puts "#{__LINE__}. Start of photo processing. First read EXIF info and write to instructions and optionally to caption for viewing in Mylio
Also for later use in naming photos and putting aside sequence (bracketed) shots contributing to stacked image
Creating an array with some EXIF and other info for use later with renaming
Will take a bit of time. FIXME: add some progress bar"
# Dir.each_child(src) do |fn| # can be random order

# Go through each photo and write a few things to the files and establish photo_array for processing each photo in rename
# This is a slow process, so eliminate any fields not needed in renamePhotoFiles FIXME
Dir.each_child(src).sort.each do |fn|
	next if fn == '.DS_Store' # each_child knows about . and .. but not 
	id += 1
  preservedFileName = fileName = fn # FIXME or maybe I should go with Ruby syntax of basename
	fileExt = File.extname(fn).strip.downcase[1..-1] # should be faster than fileEXIF.fileType and .ori doesn't get converted to .orf. strip to get rid of period
	# sameSecond = 1 # resets to zero if previous file not in same second. Was 
	# redefine fn
  fn  = src + "/" + fn
	# Request FileName explicitly. FileName is a system tag, not in EXIF. 
	fileEXIF = MiniExiftool.new(fn)
	camModel = fileEXIF.model
	# fileName = fileEXIF.FileName # shows up in exiftool, but not here and can't seem to be forced, but see above:
	fileType = fileEXIF.fileType # FileType : JPEG. FileTypeExtension yields three letter lower case.
	# fileExt = fileEXIF.FileTypeExtension # three character extension. OM EXIF for FileType and FileTypeExt for an .ori is ORF
	createDate = fileEXIF.CreateDate
	# timeStamp = fileEXIF.TimeStamp  # doesn't exist? and not using
	offsetTimeOriginal = fileEXIF.OffsetTimeOriginal # ~ time zone
	# model = fileEXIF.model
	# fileExt = File.extname(fn).tr(".","").downcase # used this before found FileTypeExtension, now defined above
	driveMode = fileEXIF.DriveMode 

	case 
	when fileExt == "mov" # OMDS movie
		dateTimeOriginal = fileEXIF.CreateDate
		# Are these needed. Maybe to prevent errors
		shootingMode = "MOV"
		shotNo = ""
	else 
		dateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
		shootingMode = driveMode.split(',')[0] # Focus Bracketing or whatever is before the first comma
		shotNo = driveMode.match(/(\d{1,3})/).to_s.rjust(2, '0')
	end

	subjectTrackingMode = fileEXIF.AISubjectTrackingMode
	stackedImage = fileEXIF.StackedImage
	afPointDetails = fileEXIF.AFPointDetails
	# filterEffect = fileEXIF.FilterEffect Exist for OM
	# focusBracketStepSize = fileEXIF.FocusBracketStepSize # removed as didn't see any use
	fileSubSecTimeOriginal = fileEXIF.SubSecTimeOriginal # no error if doesn't exist and it does not puts in OM
	instructions = fileEXIF.instructions 
	timeZoneOffset = fileEXIF.TimeZoneOffset
	specialMode = fileEXIF.specialMode # Not sure what's in here, but is OM specific and maybe useful?
	
	# Intermediate values and .mov has to be handled differently. I think this is handled above
	# if fileType == "MOV" # driveMode == "" # nil doesn't work, neither does blank
	# 	shootingMode = "MOV" 
	# 	shotNo = ""
	# 	dateTimeOriginal = fileEXIF.CreateDate # Not necessary since OM mov has a createDate and dateTimeOriginal
	# else
	# 	shootingMode = driveMode.split(',')[0] # Focus Bracketing or whatever is before the first comma
	# 	shotNo = driveMode.match(/(\d{1,3})/).to_s.rjust(2, '0')
	# 	dateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
	# end
	
	# Changing one field So Preview and some other Apple apps can open the files. If and when Apple adds OM-1 Mark II, can remove this line. 15.2 Still can't open
	fileEXIF.CameraType2 = "OM-1" #  CameraType2 was 'Unknown (S0121)'

	# Creating expressive Caption for evaluating shooting techniques. Can toggle on and off below and will establish selecting the option in the GUI
	imageDescription = "" # so not carried over from previous photo
	# Only put in if value is present
	unless stackedImage.nil? # Note unless here and if ! next. Always a value except for .mov. Don't need to see No
		imageDescription = stackedImage + " [StackedImage]. "
		instructions = stackedImage + ". " + shootingMode
	end
	# puts "#{__LINE__}. driveMode: #{driveMode}.  driveMode.present?: #{driveMode.present?}."
	if !driveMode.nil? # .present? didn't work
		imageDescription << driveMode + " [DriveMode]. "
	end
	# if !filterEffect.nil?
	# 	imageDescription << filterEffect + " [FilterEffect]. "
	# end
	unless afPointDetails.nil?
		imageDescription << afPointDetails + " [AFPointDetails]"
	end
	# unless focusBracketStepSize.nil?
	# 	imageDescription << " ." + focusBracketStepSize.to_s + " [FocusBracketStepSize]"
	# end
	# In general don't want to write this, but maybe during evaluating shooting techniques, so add to GUI on whether to do it.
	writeCaption = true # Decide this is GUI later
	fileEXIF.description = imageDescription if writeCaption == true
	# end imageDescription
	
	# Instruction, similar to description except description is Caption and in general don't want to use it. Instructions is visible in Mylio, so not as convenient, but is available
	# if focusBracketStepSize.nil?
	#   instructions = "STM: " + subjectTrackingModeOne + ". SM:" + shootingMode
	# else
	#   instructions = "STM: " + subjectTrackingModeOne + ". SM:" + shootingMode + ". FocusBrkStep " + focusBracketStepSize.to_s + " "
	# end
	
	fileEXIF.instructions = "#{instructions}. #{File.basename(fn,".*")}" # Maybe drop basename
	fileEXIF.preservedFileName = preservedFileName

	fileEXIF.save # only change so far is imageDescription and instructions
	
	# Mark photos in same second. Can I avoid checking for >1 since only needed for first round FIXME
	if createDate == createDatePrev && fileExtPrev == fileExt
		puts "\n#{__LINE__}. #{id}.  sameSecond: #{sameSecond}. #{fileName}. #{createDate}." if showPuts == true
	  if sameSecond >= 2 # now dealing with the third since sameSecond was set for the previous
			sameSecond += 1
			puts "#{__LINE__}. #{id}.  sameSecond: #{sameSecond}. #{fileName}. #{createDate}." if showPuts == true
		else # the first pair identified, but haven't noted that the one before this needs to be given a sequence no
			# and write same second true for previous photo		
			photo = photo_array.find { |p| p.id == photo_id_prev } # getting id for previous photo
			photo.sameSecond = 1 # setting the previous photo to 1
			puts "#{__LINE__}. #{id}.  sameSecond: #{sameSecond}. for previous file since it was previous a zero." if showPuts == true
			sameSecond = 2 # the current photo is the second pair of sameSecond
			puts "#{__LINE__}. #{id}.  sameSecond: #{sameSecond}. for current file which is the first time a pair has been identified #{fileName}. #{createDate}." if showPuts == true
		end # 
	else # if sameSecond # resetting after going through some pairs. Should only have to do this once but seemingly doing it each time
		sameSecond = 0 # or maybe nil
		puts "#{__LINE__}. #{id}.  sameSecond: #{sameSecond}. #{fileName}. #{createDate}." if showPuts == true # error if photo_id
	end # if createDate == createDatePrev
	createDatePrev = createDate
	fileExtPrev = fileExt
	photo_id = photo_id_prev = "photo-" + id.to_s # FIXME. Get rid of `photo-`. was helpful in figuring it all out, but now not needed
	# puts "#{__LINE__}. #{photo_id}.  sameSecond: #{sameSecond}. #{fileName}. #{createDate}." if showPuts == true
	photo_array <<	Photo.new(photo_id, fn, fileName, fileExt, camModel, fileType, stackedImage, driveMode, specialMode, afPointDetails, subjectTrackingMode, createDate, sameSecond, dateTimeOriginal, offsetTimeOriginal, preservedFileName)
	# Checking what is stored in stacked image
	# puts "#{id}. Stacked Image: `#{stackedImage}`. shotNo: #{shotNo}. driveMode: #{driveMode}.  Original FileName: #{preservedFileName}" # DEV
end # Dir.each_child(src).sort.each do |fn|
puts "\n#{__LINE__}. Finished adding EXIF info and establishing photo array. If want to see some data for each photo, uncomment two lines above."
puts photo_array.inspect if putsArray # DEV set ib kube 15
# puts "#{__LINE__}. ######## End of Array ##########"
# Renaming. Look at original, not sure what is going on exactly Line 1253
# puts "\n{__LINE__}. Rename [tzoLoc = renamePhotoFiles(…)] the photo files with date and an ID for the camera or photographer (except for the paired jpgs in #{tempJpg}). #{timeNowWas}\n"
puts "\n#{__LINE__}. renamePhotoFiles(…)] the photo files with date and an ID for the camera or photographer. #{timeNowWas}\n"
# tzoLoc = timeZone(dateTimeOriginal, timeZonesFile) # Second time this variable name is used, other is in a method
# puts "\n#{__LINE__}. photo_array: #{photo_array}\n"
renameReturn = renamePhotoFiles(photo_array, mylioStaging, timeNowWas, photosRenamedTo, unneededBrackets, showPuts, addPreservedNameForDebugging) # This also calls rename which processes the photos, but need tzoLoc value. Negative because need to subtract offset to get GMT time. E.g., 10 am PST (-8)  is 18 GMT


# puts "\n#{__LINE__}.  Demo of retrieving info from array:"
# photo_10 = photo_array.find { |photo| photo.id == "photo-10" }
# puts "   #{__LINE__}. photo_id: photo-10.  Stacked Image: #{photo_10.stackedImage if photo_10}. photo_10.preservedFileName: #{photo_10.preservedFileName}. "

timeNowWas = timeStamp(timeNowWas, lineNum)

# Add GPS coordinates.
puts "\n#{__LINE__}. Using exiftool to add gps coordinates. Will take a while as all the gps files for the year will be processed and then all the photos."
exiftoolAddCoordinates(mylioStaging, folderGPX)

timeNowWas = timeStamp(timeNowWas, lineNum)
puts "#{__LINE__}. Time to add coordinates: #{timeNowWas}"

# Before made a list of files and copied. Will change with objects
# copySD(srcSD, srcHD, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) if whichOne == "SD"
puts "\n#{__LINE__}. #{Dir[File.join(mylioStaging, '**', '*')].count { |file| File.file?(file) }} files in output folder: #{mylioStaging}." # NOT WORKING" Dir[path].length
# lineNum = "#{__LINE__} + 1" # What's this?
timeNowWas = timeStamp(timeNowWas, lineNum)