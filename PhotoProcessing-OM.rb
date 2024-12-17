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

class Photo
	
	@@count = 0
	
	attr_accessor :id, :fn, :fileName, :fileExt, :camModel, :fileType, :stackedImage, :driveMode, :specialMode, :afPointDetails, :subjectTrackingMode, :createDate, :dateTimeOriginal, :offsetTimeOriginal, :preservedFileName
	# order by need for sorting and dealing with

  def initialize(id, fn, fileName, fileExt, camModel, fileType, stackedImage, driveMode, specialMode, afPointDetails, subjectTrackingMode, createDate, dateTimeOriginal, offsetTimeOriginal, preservedFileName)
		
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
		@dateTimeOriginal = dateTimeOriginal,
		@offsetTimeOriginal = offsetTimeOriginal
		@preservedFileName = preservedFileName
  end
		
end # class photo

HOME = "/Users/gscar/"
thisScript = "#{File.dirname(__FILE__)}/" # needed because the Pashua script calling a file seemed to need the directory. 
# thisScript = File.dirname(__FILE__) +"/" # needed because the Pashua script calling a file seemed to need the directory.
photosRenamedTo = thisScript + "currentData/photosRenamedTo.txt" 

# unneededBracketed = downloadsFolders + "Unneeded brackets/" # on Daguerre
unneededStacksFolder = thisScript + "/testingDev/unneededStacksFolder" # DEV

# srcHD       = downloadsFolders + " Drag Photos HERE/" # 
# srcHD = "testingDev/incomingTestPhotos"

# Adding each file to Array photos
# temp src until determine using. Full path needed to run from arbitrary place in iTerm. Relative works in Nova
src = thisScript + "/testingDev/incomingTestPhotos/" # Stacked w/ and w/o a stacked image, HHHR, THR, 
# src = "/Volumes/Daguerre/_Download folder/_imported-archive/OM-1/OB[2024.11]-OM/" # 308 photos
# src = "/Volumes/Daguerre/_Download folder/_imported-archive/OM-1/OA[2024.10]-OM/" # 476 photos
# src = thisScript + "/testingDev/singleTestPhoto"

# mylioStaging = downloadsFolders + "Latest Processed photos-Import to Mylio/" #  These are relabeled and GPSed files. Will be moved to Mylio after processing.
mylioStaging = thisScript + "/testingDev/staging" # DEV
# Not planning to use initially or at all
timeZonesFile = thisScript + "currentData/Greg camera time zones.yml"

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

def oneBackTrue(src, fn, fnp, fnpPrev, fileDateStr, driveMode, dupCount, camModel, userCamCode)
	# Some of these fields may not be needed, I was fighting the wrong problem and may have added some that aren't needed
	# puts "\n#{__LINE__}. fn: #{fn}. fnp: #{fnp}. subSecExists: #{subSecExists}. fileDate: #{fileDate}. driveMode: #{driveMode}.  dupCount: #{dupCount}. in oneBackTrue(). DEBUG"
	dupCount += 1
	# Getting sequence no./shot no. for OM-1. DriveMode is "Single Shot; Electronic shutter" for normal photos
	unless driveMode.nil? || driveMode.empty? # opposite of if, therefore if driveMode is not empty
		match = driveMode.match(/Shot (\d{1,3})/)
		shot_no = match[1].to_i if match
		shootingMode = driveMode.split(',')[0]
		# puts "#{__LINE__}. fn: #{fn}. driveMode: #{driveMode}. shot_no: #{shot_no}. shootingMode: #{shootingMode}. subSecExists: #{subSecExists}. fileDateStr: #{fileDateStr}. DEBUG"
	end
	if shot_no.to_i > 0 # photos without subsecs. OM-1 but with shot number.
		# Getting sequence no. for OM-1. DriveMode is "Single Shot; Electronic shutter" for normal photos
			 # puts shot_no
		# End getting seqence no
		# fileBaseName = fileDateStr + "-" + shot_no.to_s + userCamCode
		fileBaseName = "#{fileDateStr}-#{shot_no.to_s}#{userCamCode}"
		# puts "#{__LINE__}. fn: #{fn} in 'if oneBack'. fileBaseName: #{fileBaseName}. fileDateStr: #{fileDateStr}. shot_no: #{shot_no}. userCamCode(fn): #{userCamCode(fn)}. DEBUG" # .  filtered: #{filtered}
	else # photos without subsecs, pre GX8 and other OM-1 in same second
		# puts "#{__LINE__}. fn: #{fn} in 'if oneBack'. fileDateStr: #{fileDateStr}. dupCount: #{dupCount}. userCamCode(fn): #{userCamCode(fn)}. debug"
		# fileBaseName = fileDateStr +  seqLetter[dupCount] + userCamCode(fn) + filtered
		# Giving up on seqLetter because too many, use dupCount, but also add shot no. 
		
		# FIXME. I think the next 12 or so lines are not being used.
		# driveMode = fileEXIF.DriveMode # '-DriveMode : Continuous Shooting, Shot 12; Electronic shutter'
		# puts "#{__LINE__}. driveMode: #{driveMode}. driveMode.class: #{driveMode.class} for . " # error if?
		if driveMode.class == "NilClass"
			# fileBaseName = fileDateStr + "-" + dupCount.to_s + userCamCode
			fileBaseName = "#{fileDateStr}-#{dupCount.to_s}#{userCamCode}"
			puts "#{__LINE__} #{fileBaseName} has dupCount" # debug 
		elsif driveMode.length > 0
			match = driveMode.match(/Shot (\d{1,3})/)
			if match
				shot_no = match[1].to_i
				puts "#{__LINE__} #{fileDateStr} is shot that contributed to a Focus Stacked image" # debug 
			else 
				shot_no = "FS" # for an in camera Focus Stacked image FIXME. This should not be in oneBackTrue
				puts "\n#{__LINE__} #{fileDateStr} an in camera Focus Stacked image and the contributing images should not be sent to Mylio." # debug
			end
			fileBaseName = "#{fileDateStr}-#{dupCount.to_s}(#{shot_no})#{userCamCode}"
			
			# fileBaseName = fileDateStr + "-" + dupCount.to_s + ".FS" + userCamCode(fn) # for an in camera Focus Stacked image
		else
			puts "#{__LINE__}. driveMode: #{driveMode}. driveMode.class: #{driveMode.class}." 
			# fileBaseName = fileDateStr + "-" + dupCount.to_s  + userCamCode
			fileBaseName = "#{fileDateStr}-#{dupCount.to_s}#{userCamCode}"
		end
		
		puts "#{__LINE__}. fn: #{fn} in 'if oneBack'.     fileBaseName: #{fileBaseName}."
	end # subSecExists
	return fileBaseName
end # oneBackTrue

# Add original file name, rename with coding
def renamePhotoFiles(photo_array, src, timeZonesFile, timeNowWas, photosRenamedTo, unneededStacksFolder)
		# Use photo_array of all the photos bringing in. Read fields needed to process photos
	# 1. If focused-stacked (stackedImage), get count and confirm next x are Focus Bracketing and set aside and mark as brackets. ~Line 208
	# 2. 
	
	# src is mylioStaging folder ??
	# timeZonesFile is my log of which time zones I was in when
	# timeNowWas used for timing various parts of the script.
	puts "\n#{__LINE__}. Just entered renamePhotoFiles. timeZonesFile #{timeZonesFile}.  #{timeNowWas}\n" #  src: #{src}. an object? 
	# Until 2017, this assumed camera on UTC, but doesn't work well for cameras with a GPS or set to local time
	# So have to ascertain what time zone the camera is set to by other means in this script, none of them foolproof
	# 60 minutes for ~1000 photos to rename TODO ie, very slow
	fn = fnp = fnpPrev = "" # must declare variable or they won't be available everywhere in the module
	# subSecPrev = subSec = ""
	fileDatePrev = ""
	dupCount = 0
	count    = 1
	tzoLoc = ""
	camModel = ""
	userCamCode = ".gs.O." # go back to older version of this if want to determine it
	seqLetter = %w(a b c d e f h i j k l m n o p q r s t u v w x y z aa bb cc dd ee ff gg hh ii jj kk ll mm nn oo pp qq rr ss tt uu vv ww xx yy zz) # used when subsec doesn't exist, but failing for large sequences possible on OM-1, so maybe use sequential numbers, i.e., dupCount?. Yes
# Have to re-establish the field names and class since the array doesn't carry the class (a db might have been better)
	unneededBracketedFiles = [] # ~line 781
	stackedImageBoolean = false # Needed for first time through the array.each

	# photo_array.each_with_index do |photo, index| if need index number
	# puts "\n#{__LINE__}. photo_array: #{photo_array}\n"
	puts "\n#{__LINE__}. Entering	`photo_array.reverse.each do |photo|` in renamePhotoFiles(\n" 
	photo_array.reverse.each do |photo|
		fn = photo.fn # file_name
		# puts "\n#{__LINE__}. fn: #{fn}." 
		dateTimeOriginal = photo.dateTimeOriginal
		# puts "\n#{__LINE__}. preservedFileName: #{photo.preservedFileName}.	dateTimeOriginal: #{dateTimeOriginal}. " # sorting out what I was trying to do
		fileDate = dateTimeOriginal
		# puts "\n#{__LINE__}. fileDate: #{fileDate}. fileDate.class: #{fileDate.class}." #  fileDate: [2024-10-18 10:52:30 -0700, "-07:00"]. fileDate.class: Array. DEV
		fileDateStr = Time.parse(fileDate.to_s).to_s[0..-7].gsub(/-/, '.').gsub(' ', '-').gsub(/:/, '.') # to_s twice? FIXME then chop off time_zone, then change spaces, dashes, and colons to what I want
		# puts "\n#{__LINE__}. fileDateStr: #{fileDateStr}. But want to look like this `2024.10.30-16.28.54`"
			
		# dateTimeOriginalstr = dateTimeOriginal.to_s[0..-10]		
		# puts "#{__LINE__}. dateTimeOriginalstr: #{dateTimeOriginalstr}.  dateTimeOriginal: #{dateTimeOriginal}. \n Do I need both of these FIXME" 
				# puts "\n#{__LINE__}. fn: #{fn}\n"
				
		# For photos in same second, but not bracketing (can check by shot no.)
		fileExt = photo.fileExt
		fileExtPrev = ""
			
		# Change OM .ORI to .ORI.ORF so Apple apps and others can see them. Can't do before fileEXIF.save because fn is "redefined". Hi-Res creates an .ORI
		# Focus stacked first image gets renamed somewhere else and loses the .ori at line 555?
		# But it does get the .ORI.ORF but then gets changed.
		if fileExt == "ori"
			f_rename = fn + ".ORF"
			fn_orig = File.new(fn)
			# puts "fn.class: #{fn.class}"
			# puts "\n#{__LINE__}. #{fn_orig} (fn_orig)to\n#{f_rename} (fn)about to happen"
			File.rename(fn_orig, f_rename)
			fn = f_rename # since reuse fn
			# puts "#{__LINE__}. Rename happened and now fn is #{fn}." 
		end 

		# Add  1. If focused-stacked (stackedImage), get count and confirm next x are Focus Bracketing and set aside and mark as brackets
		stackedImage = photo.stackedImage
		driveMode = photo.driveMode # how long does this take? If don't need at highest level check later
		# stackedImageBoolean = false # declared below and would be wrong here
		
		# High resolution can either be Tripod or Hand Held
		hiResTripodBoolean = false
		hiResHandheldBoolean = false
		
		# Looking for bracketed images if a stackedImage exists
		# stackedImageBoolean = true if previous image (remember going backwards) is a StackedImage
	 # if stackedImage[0..12].to_s == "Focus-stacked" # will this work?
		# if `Focus Bracketing` (and Shot no >1 and <100 could be added if needed to make sure) rename as bracket and set aside
		# check stackedImageBoolean = true which will exclude most. Maybe make a method
		if stackedImageBoolean
			# Now check to make sure image is a bracketed image
			driveModeFb = driveMode.split(',')[0]
			# puts "#{__LINE__}. driveModeFb: #{driveModeFb}."  #Focus Bracketing
			if driveModeFb.to_s == "Focus Bracketing"
				match = driveMode.match(/(\d{1,3})/) # Getting shot no. from `Focus Bracketing,  Shot _`
				# shot_no = match[1].to_i # if match # has to be a match in this loop, so maybe don't need the if
				shot_no = match[1]
				# 2024.10.30-16.28.54_08bkt.gs.O.jpg
				# stackBracket = "_" + shot_no.to_s.rjust(2, '0') + "bkt" # trying to tighten name compared to above
				fileBaseName = "#{fileDateStr}-#{shot_no}bkt#{userCamCode}"
				puts "\n#{__LINE__}. fileBaseName: #{fileBaseName}. Working through bracketed images for which a stack exists" 
			else
				stackedImageBoolean = false # worked through the images and move onto the next check
				puts "Worked through the bracketed #{shot_no} images"
			end # if driveModeFB
		end # if stackedImageBoolean
		
		unless stackedImage.nil? # nil for .mov
	
			if stackedImage[0..12].to_s == "Focus-stacked"
				bracketCount = stackedImage[15..16] # there is a space after the final digit, so either 1 or 2 digits.
				puts "\n#{__LINE__}. #{fn} is a successfully stacked images with #{bracketCount} brackets.\n Now put aside next #{bracketCount} images and rename as brackets"
				fileBaseName = "#{fileDateStr}(FS)#{userCamCode}" # Inconsistent naming FIXME? could be _STK_
				stackedImageBoolean = true
			end
			
			if stackedImage[0..5].to_s == "Tripod" #  Tripod high resolution
				hiResTripodBoolean = true
				fileBaseName = "#{fileDateStr}.HiResTripod.#{userCamCode}" # period or -
			end
			
			if stackedImage[0..24].to_s == "Hand-held high resolution" # Hand-held high resolution
				hiResHandheldBoolean = true
				fileBaseName = "#{fileDateStr}HiResHand#{userCamCode}"
			end
		end	# unless
		
		oneBack = fileDate == fileDatePrev && fileExt != fileExtPrev # at the moment this is meaningless because all of one type?
		
		#  '-DriveMode : Continuous Shooting, Shot 12; Electronic shutter'. This exists for OM-1 for at least some sequence shooting. Also: `SpecialMode                     : Fast, Sequence: 9, Panorama: (none)`
		# SpecialMode may be more useful since zero if not a sequence : Normal, Sequence: 0, Panorama: (none)
		# But DriveMode can tell what kind of sequence, although not sure that's needed in this script
		# driveMode = fileEXIF.DriveMode # OMDS only, not in Lumix. Moved definition up as need earlier
		# DriveMode       : Focus Bracketing, Shot 8; Electronic shutter
		# DriveMode shows "Focus Bracketing" for the shots comprising the focus STACKED result
		specialMode = photo.specialMode # Initially no use for specialMode, but will carry for a while FIXME
		# driveMode = photo.driveMode
		# unless driveMode.nil? # doesn't exist in some cases: only .mov AFAIK
		# 	driveModeFb = driveMode.split(',')[0]
		# 	# puts "#{__LINE__}. driveModeFb: #{driveModeFb}."  #Focus Bracketing
		# 	# Focus Bracketing is the only driveMode I'v seen so far. Single Shot being the 'default'
		# 	if driveModeFb.to_s == "Focus Bracketing"
		# 		bracketing = true
		# 	else
		# 		bracketing = false
		# 	end
		# end
	
		match, shot_no = ""
		
		# puts "#{__LINE__}. fn: #{fn}. driveMode: #{driveMode}.\nspecialMode: #{specialMode} oneBack: #{oneBack} = true is two photos in same second. If true, oneBackTrue will be called."
		# Maybe should enter if there is a shot no.
		unless driveMode.nil? || driveMode.empty? # opposite of if, therefore if driveMode is not empty. Only nil for .mov
			match = driveMode.match(/(\d{1,3})/) # Getting shot no. from `Continuous Shooting, Shot 12; Electronic shutter`
			shot_no = match[1].to_i if match
			# First photo in a sequence won't get -1 in oneBackTrue.
			if shot_no.to_i == 1
				# puts "\n#{__LINE__}. fileDate: #{fileDate}.	of class: #{fileDate.class}. fileDate.to_s: #{fileDate.to_s}.	" 
				# fileBaseName = fileDateStr + "-" + shot_no.to_s.rjust(2, '0') + userCamCode #  fBmark +
				fileBaseName = "#{fileDateStr}-#{shot_no.to_s.rjust(2, '0')}#{userCamCode}"
				puts "#{__LINE__}. Because this was the first in a sequence a `1` was added to the filename for #{fileBaseName}. DEBUG" # Working for OM
			end
		
		# puts "#{__LINE__}. oneBack: #{oneBack}. match: #{match}. DEBUG"

			# puts "#{__LINE__} stackedImage[0..12]: #{stackedImage[0..12]}. stackedImageBoolean: #{stackedImageBoolean}" #  stackedImage[0..12]: Focus-stacked. stackedImageBoolean: false
			# if bracketing or stackedImageBoolean
			# 	# fB for Focus Bracket. Bkt for bracket. The logic isn't the greatest to show whats going on. Assumed bracketed unless stacked
			# 	# stackBracket = "_" + shot_no.to_s.rjust(2, '0') + "_Bkt" _fB
			# 	stackBracket = "_" + shot_no.to_s.rjust(2, '0') + "bkt" # trying to tighten name compared to above
			# 	# _FS for Focus Stacked. _Stk for stacked. Do I need to diffential different stacking modes
			# 	stackBracket = "_STK" if stackedImageBoolean # _FS. All caps to stand out from Bkt
			# 	fileBaseName = "#{fileDateStr}#{stackBracket}#{userCamCode}"
			# elsif oneBack # || match # Two photos in same second? 
			# 	puts "#{__LINE__} if oneBack || match. oneBack: #{oneBack}. match: #{match}. DEBUG"
			# 	fileBaseName = oneBackTrue(src, fn, fnp, fnpPrev, fileDateStr, driveMode, dupCount, camModel, userCamCode)
			# else # normal condition that this photo is at a different time than previous photo
			# 	# puts "#{__LINE__} if oneBack || match. oneBack: #{oneBack}. match: #{match} for item: #{item}. DEBUG"
			# 	dupCount = 0 # resets dupCount after having a group of photos in the same second
			# 	fileBaseName = "#{fileDateStr}#{userCamCode}" #  + filtered + fBmark 
			# 	# puts "#{__LINE__}. item: #{item} is at different time as previous.    fileBaseName: #{fileBaseName}"
			# end # if oneBack
			# puts "\n#{__LINE__}. fileBaseName: #{fileBaseName}. not sure where we are here DEV" 
			fileDatePrev = fileDate
			fileExtPrev = fileExt
			# fileBaseNamePrev = fileBaseName
			
			# write to Instructions which can be seen in Mylio and doesn't interfere with Title or Caption
			# Seems like this is done elsewhere
			# fileAnnotate(fn, dateTimeOriginalstr, tzoLoc, camModel) # was passing fileEXIF, but saving wasn't happening, so reopen in the module?
	
			# fnp = fnpPrev = src + "/" + fileBaseName + fileExt.downcase
			
			fnp = fnpPrev  = "#{src}\/#{fileBaseName}#{fileExt.downcase}"
			# puts "\n#{__LINE__}. fnp: #{fnp}." 
			# fnp = "Placeholder for DEV"
			# puts "Place holder to make the script work. where did the unless come from"
      puts "\n#{__LINE__}. fn: #{fn}. fn.class: #{fn.class}\nfnp (fnpPrev): #{fnp}"
			puts "\n#{__LINE__}. fn exists: #{File.file?(fn)}. fnp exists: #{File.file?(fnp)} of course not yet."
			
			# Ensure destination directory exists DEV, because wiping this out in DEV
			destination_dir = File.dirname(fnp)
			FileUtils.mkdir_p(destination_dir)
		
			File.rename(fn,fnp) ## 
			# Add the processed file to the array so can move unneeded bracket files below
			# unneededBracketedFiles << fnp
	
			count += 1
		else
			# puts "#{__LINE__}. CHECKING why `if File.file?(fn)` is needed. File.file?(fn): #{File.file?(fn)} for fn: #{fn}"
		end # 3. if File.file?(fn)
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

puts "\n#{__LINE__}. Copy 'virgin' photos to simulated incoming folder. Adding EXIF in place so need virgin to start. Delete /testPhotos and /incomingTestPhotos so folders empty to start DEV\n"
testPhotos = 'testingDev/incomingTestPhotos'
FileUtils.rm_rf(testPhotos) # clear out incoming in case some left DEV
FileUtils.rm_rf(mylioStaging) # clear out photos from previous run DEV
# puts value.x # created an error here so script would stop and I could check that folder was deleted and it was

# For DEV to have sample files to test with. Only one selected below
# FileUtils.cp_r('testingDev/virginOMcopy2incoming', testPhotos, preserve: true, remove_destination: true ) # preserve to keep timestamp (may not be necesary). cp_r is for directory. This directory has a currated batch of photos
puts "\n#{__LINE__}. Not using full test stack of photos" 
FileUtils.cp_r('testingDev/bracketStackTestPhotos', testPhotos, preserve: true, remove_destination: true ) # just a stack for DEV test

lineNum = "#{__LINE__}"
timeNowWas = timeStamp(Time.now, lineNum)
id = 0
photo_array = []
lastPhotoFilename = "OB305994" # use later as starting point

puts "#{__LINE__}. Start of photo processing. First read EXIF info and write to instructions and optionally to caption for viewing in Mylio
Also for later use in naming photos and putting aside sequence (bracketed) shots contributing to stacked image
Creating an array with some EXIF and other info for use later with renaming
Will take a bit of time. FIXME: add some progress bar"
# Dir.each_child(src) do |fn| # can be random order
Dir.each_child(src).sort.each do |fn|
	next if fn == '.DS_Store' # each_child knows about . and .. but not 
	id += 1
  preservedFileName = fn
	# redefine fn
  fn  = src + "/" + fn
	fileEXIF = MiniExiftool.new(fn)
	camModel = fileEXIF.model
	fileName = fileEXIF.fileName
	fileType = fileEXIF.fileType
	createDate = fileEXIF.CreateDate
	timeStamp = fileEXIF.TimeStamp
	offsetTimeOriginal = fileEXIF.OffsetTimeOriginal
	# model = fileEXIF.model
	
	fileExt = File.extname(fn).tr(".","").downcase 
	case 
	when fileExt == "mov" # OMDS movie
		dateTimeOriginal = fileEXIF.CreateDate
	else 
		dateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
	end

	driveMode = fileEXIF.DriveMode 
	if fileType == "MOV" # driveMode == "" # nil doesn't work, niether does blank
		shootingMode = "MOV"
		shotNo = ""
		dateTimeOriginal = fileEXIF.CreateDate # FIXME do I need both createDate and dateTimeOriginal? mov has no dateTimeOriginal.
	else
		shootingMode = driveMode.split(',')[0] # Focus Bracketing or whatever is before the first comma
		shotNo = driveMode.match(/(\d{1,3})/).to_s.rjust(2, '0')
		dateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
	end
	subjectTrackingMode = fileEXIF.AISubjectTrackingMode
	stackedImage = fileEXIF.StackedImage
	afPointDetails = fileEXIF.AFPointDetails
	filterEffect = fileEXIF.FilterEffect
	# focusBracketStepSize = fileEXIF.FocusBracketStepSize # removed as didn't see any use
	fileSubSecTimeOriginal = fileEXIF.SubSecTimeOriginal # no error if doesn't exist and it does not puts in OM
	instructions = fileEXIF.instructions 
	timeZoneOffset = fileEXIF.TimeZoneOffset
	specialMode = fileEXIF.specialMode # Not sure what's in here, but is OM specific and maybe useful?
	
	# Intermediate values and .mov has to be handled differently
	if fileType == "MOV" # driveMode == "" # nil doesn't work, niether does blank
		shootingMode = "MOV" 
		shotNo = ""
		dateTimeOriginal = fileEXIF.CreateDate # Not necessary since OM mov has a createDate and dateTimeOriginal
	else
		shootingMode = driveMode.split(',')[0] # Focus Bracketing or whatever is before the first comma
		shotNo = driveMode.match(/(\d{1,3})/).to_s.rjust(2, '0')
		dateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
	end
	
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
	if !filterEffect.nil?
		imageDescription << filterEffect + " [FilterEffect]. "
	end
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
	
	
	# FIXME What are the next ~20 lines about?
	# tzoLoc = timeZone(dateTimeOriginal, timeZonesFile) # the time zone the picture was taken in, doesn't say anything about what times are recorded in the photo's EXIF. I'm doing this slightly wrong, because it's using the photo's recorded date which could be either GMT or local time. But only wrong if the photo was taken too close to the time when camera changed time zones
	# # puts "#{__LINE__}. #{count}. tzoLoc: #{tzoLoc} from timeZonesFile"
	# 
	# # count == 1 | 1*100 ?  :  puts "."  Just to show one value, otherwise without if prints for each file; now prints every 100 time since this call seemed to create some line breaks and added periods.
	# # Also determine Time Zone TODO and write to file OffsetTimeOriginal	(time zone for DateTimeOriginal). Either GMT or use tzoLoc if recorded in local time as determined below
	# # puts "#{__LINE__}.. camModel: #{camModel}. #{tzoLoc} is the time zone where photo was taken. Script assumes GX8 on local time "
	# # Could set timeChange = 0 here and remove from below except of course where it is set to something else
	# timeChange =  0 # 3600 *  # setting it outside the loops below and get reset each time through. But can get changed
	# # puts "#{__LINE__}. camModel: #{camModel}. fileEXIF.OffsetTimeOriginal: #{fileEXIF.OffsetTimeOriginal}"
	# if camModel ==  "MISC" # MISC is for photos without dateTimeOriginal, e.g., movies
	# 	# timeChange = 0
	# 	fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
	# 	# puts "#{__LINE__}. dateTimeOriginal #{dateTimeOriginal}. timeChange: #{timeChange} for #{camModel} meaning movies. DEBUG"
	# elsif camModel == "iPhone X"  # DateTimeOriginal is in local time
	# 	# timeChange = 0
	# 	# fileEXIF.OffsetTimeOriginal = tzoLoc.to_s # redefined below.
	# 	timeChange = (3600*tzoLoc) # previously had error capture on this. Maybe for general cases which I'm not longer covering
	# 	fileEXIF.OffsetTimeOriginal = "GMT" # say what?
	# 	# puts "#{__LINE__}.. dateTimeOriginal #{dateTimeOriginal}. timeChange: #{timeChange} for #{camModel}" if count == 1 # just once is enough
	# end # if camModel


	fileEXIF.save # only change so far is imageDescription and instructions
	
	photo_id = "photo-" + id.to_s
	photo_array <<	Photo.new(photo_id, fn, fileName, fileExt, camModel, fileType, stackedImage, driveMode, specialMode, afPointDetails, subjectTrackingMode, createDate, dateTimeOriginal, offsetTimeOriginal, preservedFileName)
	# Checking what is stored in stacked image
	# puts "#{id}. Stacked Image: `#{stackedImage}`. shotNo: #{shotNo}. driveMode: #{driveMode}.  Original FileName: #{preservedFileName}" # DEV
end # Dir.each_child(src).sort.each do |fn|
puts "\n#{__LINE__}. Finished adding EXIF info and establishing photo array. If want to see some data for each photo, uncomment two lines above."
# puts photo_array.inspect # DEV
# puts "#{__LINE__}. ######## End of Array ##########"
# Renaming. Look at original, not sure what is going on exactly Line 1253
# puts "\n{__LINE__}. Rename [tzoLoc = renamePhotoFiles(…)] the photo files with date and an ID for the camera or photographer (except for the paired jpgs in #{tempJpg}). #{timeNowWas}\n"
puts "\n#{__LINE__}. Rename [tzoLoc = renamePhotoFiles(…)] the photo files with date and an ID for the camera or photographer (except for the paired jpgs FIXME. #{timeNowWas}\n"
# tzoLoc = timeZone(dateTimeOriginal, timeZonesFile) # Second time this variable name is used, other is in a method
# puts "\n#{__LINE__}. photo_array: #{photo_array}\n"
renameReturn = renamePhotoFiles(photo_array, mylioStaging, timeZonesFile, timeNowWas, photosRenamedTo, unneededStacksFolder) # This also calls rename which processes the photos, but need tzoLoc value. Negative because need to subtract offset to get GMT time. E.g., 10 am PST (-8)  is 18 GMT


puts "\n#{__LINE__}.  Demo of retrieving info from array:"
photo_10 = photo_array.find { |photo| photo.id == "photo-10" }
puts "   #{__LINE__}. photo_id: photo-10.  Stacked Image: #{photo_10.stackedImage if photo_10}. photo_10.preservedFileName: #{photo_10.preservedFileName}. "
# puts Photo.count
# puts photo_id
# Before made a list of files and copied. Will change with objects
# copySD(srcSD, srcHD, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) if whichOne == "SD"

# 
# # written
# fileEXIF.PreservedFileName = "#{File.basename(fn)}" # works but does not show up in Preview, but does in Mylio, so continue to also add to Instructions above
# fileEXIF.TimeZoneOffset = tzoLoc  
# unless focusBracketStepSize.nil?
#   imageDescription << " ." + focusBracketStepSize.to_s + " [FocusBracketStepSize]"
# end
# fileEXIF.description = imageDescription
# 
# when fileExt == "mov" # OMDS movie
# dateTimeOriginal = fileEXIF.CreateDate
# else 
# dateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
# end
# 
# if camModel ==  "MISC" # MISC is for photos without dateTimeOriginal, e.g., movies
# # timeChange = 0
# fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
# # puts "#{__LINE__}. dateTimeOriginal #{dateTimeOriginal}. timeChange: #{timeChange} for #{camModel} meaning movies. DEBUG"
# elsif camModel == "iPhone X"  # DateTimeOriginal is in local time
# # timeChange = 0
# # fileEXIF.OffsetTimeOriginal = tzoLoc.to_s # redefined below.
# timeChange = (3600*tzoLoc) # previously had error capture on this. Maybe for general cases which I'm not longer covering
# fileEXIF.OffsetTimeOriginal = "GMT" # say what?
# puts "#{__LINE__}.. dateTimeOriginal #{dateTimeOriginal}. timeChange: #{timeChange} for #{camModel}" if count == 1 # just once is enough
# end # if camModel
#   

# Instantiate each file on card
# 
# For now assume know where coming from
# src = "/Volumes/Macintosh HD/Users/gscar/Library/Mobile Documents/com~apple~CloudDocs/Documents/Ruby/Photo handling/testingDev/incomingTestPhotos"
# lastPhotoFilename = "OB305994"


# Before made a list of files and copied. Will change with objects
# copySD(srcSD, srcHD, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) if whichOne == "SD"
lineNum = "#{__LINE__} + 1"
timeNowWas = timeStamp(timeNowWas, lineNum)