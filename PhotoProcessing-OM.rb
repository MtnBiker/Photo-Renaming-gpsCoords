#!/usr/bin/env ruby
# ruby "/Volumes/Macintosh HD/Users/gscar/Documents/Ruby/Photo handling/PhotoName-Class.rb"

# Written for OM-1. Copied and modified from PhotoName-GPScoord-macOSphotos.rb: #{rb}. 
# See Outline of script.txt for implemntation

require 'fileutils'
include FileUtils
require 'find'
# require 'yaml'
require "time"
require 'irb' # binding.irb where error checking is desired
require 'mini_exiftool' # `gem install mini_exiftool` have to update for 

class Photo
	
	@@count = 0
	
	attr_accessor :id, :fn, :fileExt, :camModel, :fileType, :stackedImage, :driveMode, :afPointDetails, :subjectTrackingMode, :createDate, :fileDateTimeOriginal, :offsetTimeOriginal, :preservedFileName
	# order by need for sorting and dealing with

  def initialize(id, fn, fileExt, camModel, fileType, stackedImage, driveMode, afPointDetails, subjectTrackingMode, createDate, fileDateTimeOriginal, offsetTimeOriginal, preservedFileName)
		
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
		@camModel = camModel
		@fileExt = fileExt
		@fileType = fileType
		@stackedImage = stackedImage
		@driveMode = driveMode
		@afPointDetails = afPointDetails
		@subjectTrackingMode = subjectTrackingMode
		@createDate = createDate
		@fileDateTimeOriginal = fileDateTimeOriginal,
		@offsetTimeOriginal = offsetTimeOriginal
		@preservedFileName = preservedFileName
  end
		
end # class photo

HOME = "/Users/gscar/"
thisScript = "#{File.dirname(__FILE__)}/" # needed because the Pashua script calling a file seemed to need the directory. 
# thisScript = File.dirname(__FILE__) +"/" # needed because the Pashua script calling a file seemed to need the directory.
photosRenamedTo = thisScript + "currentData/photosRenamedTo.txt" 

# unneededBracketed = downloadsFolders + "Unneeded brackets/" # on Daguerre
unneededStacksFolder = thisScript + "/testingClass/unneededStacksFolder" # DEV

# srcHD       = downloadsFolders + " Drag Photos HERE/" # 
# srcHD = "testingClass/incomingTestPhotos"

# Adding each file to Array photos
# temp src until determine using. Full path needed to run from arbitrary place in iTerm. Relative works in Nova
src = thisScript + "/testingClass/incomingTestPhotos/" # Stacked w/ and w/o a stacked image, HHHR, THR, 
# src = "/Volumes/Daguerre/_Download folder/_imported-archive/OM-1/OB[2024.11]-OM/" # 308 photos
# src = "/Volumes/Daguerre/_Download folder/_imported-archive/OM-1/OA[2024.10]-OM/" # 476 photos
# src = "testingClass/singleTestPhoto"

# mylioStaging = downloadsFolders + "Latest Processed photos-Import to Mylio/" #  These are relabeled and GPSed files. Will be moved to Mylio after processing.
mylioStaging =thisScript + "/testingClass/staging" # DEV

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

# Add original file name, rename with coding
def renamePhotoFiles(photo_array, mylioStaging, timeZonesFile, timeNowWas, photosRenamedTo, unneededStacksFolder)
	
	# src is mylioStaging folder ??
	# timeZonesFile is my log of which time zones I was in when
	# timeNowWas used for timing various parts of the script.
	puts "\n#{__LINE__}. in renamePhotoFiles. timeZonesFile #{timeZonesFile}.  #{timeNowWas}\n" #  src: #{src}. an object? 
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
	# Array to store processed files
	unneededBracketedFiles = [] # ~line 781
	# puts "#{__LINE__}. Entered rename and ready to enter foreach. src: #{src}"
	# Dir.each_child(src) do |item| # for each photo file
	# photo_array.each_with_index do |photo, index| if need index number
	# puts "\n#{__LINE__}. photo_array: #{photo_array}\n"
	photo_array.each do |photo|
		# fn = photo[:fn] # Is this needed? In any case why doesn't it work????
	fn = photo.fn
	# puts "\n#{__LINE__}. fn: #{fn}\n"
	fileExt = photo.fileExt
	fileExtPrev = ""
		
		# 
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
		fileDateTimeOriginal = photo.fileDateTimeOriginal
		fileDate = fileDateTimeOriginal + timeChange.to_i # date in local time photo was taken. No idea why have to change this to i, but was nil class even though zero  
		fileDateTimeOriginalstr = fileDateTimeOriginal.to_s[0..-6]
	
		oneBack = fileDate == fileDatePrev && fileExt != fileExtPrev # at the moment this is meaningless because all of one type?
		
		#  '-DriveMode : Continuous Shooting, Shot 12; Electronic shutter'. This exists for OM-1 for at least some sequence shooting. Also: `SpecialMode                     : Fast, Sequence: 9, Panorama: (none)`
		# SpecialMode may be more useful since zero if not a sequence : Normal, Sequence: 0, Panorama: (none)
		# But DriveMode can tell what kind of sequence, although not sure that's needed in this script
		# driveMode = fileEXIF.DriveMode # OMDS only, not in Lumix. Moved definition up as need earlier
		# DriveMode       : Focus Bracketing, Shot 8; Electronic shutter
		# DriveMode shows "Focus Bracketing" for the shots comprising the focus STACKED result
		unless driveMode.nil? # doesn't exist in some cases
			driveModeFb = driveMode.split(',')[0]
			# puts "#{__LINE__}. driveModeFb: #{driveModeFb}."  #Focus Bracketing
			if driveModeFb.to_s == "Focus Bracketing"
				bracketing = true
			else
				bracketing = false
			end
		end
			# Not using specialMode now, but as an option
		# specialMode = fileEXIF.SpecialMode
	
		match, shot_no = ""
	
		# puts "#{__LINE__}. fn: #{fn}. driveMode: #{driveMode}.\nspecialMode: #{specialMode} oneBack: #{oneBack} = true is two photos in same second. If true, oneBackTrue will be called."
		# Maybe should enter if there is a shot no.
		unless driveMode.nil? || driveMode.empty? # opposite of if, therefore if driveMode is not empty
			match = driveMode.match(/(\d{1,3})/) # Getting shot no. from `Continuous Shooting, Shot 12; Electronic shutter`
			shot_no = match[1].to_i if match
			# First photo in a sequence won't get -1 in oneBackTrue.
			if shot_no.to_i == 1
				fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + "-" + shot_no.to_s.rjust(2, '0') + userCamCode(fn) #  fBmark +
				# puts "#{__LINE__}. Because this was the first in a sequence a `1` was added to the filename for #{fileBaseName}. DEBUG" # Working for OM
			end
		
		
		# puts "#{__LINE__}. oneBack: #{oneBack}. match: #{match}. DEBUG"
		# Add check for bracketing and treat as needed, then onBack and treat as needed.
		stackedImageBoolean = false
		hiResTripodBoolean = false
		hiResHandheldBoolean = false
		# stackedImageBoolean = true if stackedImage[0..12].to_s == "Focus-stacked" # will this work? 
		unless stackedImage.nil? # OM has No, so probably never nil for OM, except maybe videos
		# FIXME to a case ?
			if stackedImage[0..12].to_s == "Focus-stacked"
			stackedImageBoolean = true
			tempTitle =  "\n#{__LINE__}. #{fn} is a successfully stacked images and (parse StackedImage to get the number of files) preceding files need to be set aside. Do this after renaming. ~line 781"
			# puts tempTitle
			# fileEXIF.title = tempTitle # doing nothing, guess file not opened at this ppomt
			
			end
			if stackedImage[0..5].to_s == "Tripod" #  Tripod high resolution
				hiResTripodBoolean = true
				fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + "HiResTripod" + userCamCode(fn)
			end
			if stackedImage[0..24].to_s == "Hand-held high resolution" #  Tripod high resolution
				hiResHandheldBoolean = true
				fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + "HiResHand" + userCamCode(fn)
			end
		end
			# puts "#{__LINE__} stackedImage[0..12]: #{stackedImage[0..12]}. stackedImageBoolean: #{stackedImageBoolean}" #  stackedImage[0..12]: Focus-stacked. stackedImageBoolean: false
			if bracketing or stackedImageBoolean
				fileBaseName = bracketed(fn, fileDate, driveMode, stackedImageBoolean, shot_no)
			elsif oneBack # || match # Two photos in same second? 
				puts "#{__LINE__} if oneBack || match. oneBack: #{oneBack}. match: #{match}. DEBUG"
				fileBaseName = oneBackTrue(src, fn, fnp, fnpPrev, subSecExists, subSec, subSecPrev, fileDate, driveMode, dupCount, camModel)
			else # normal condition that this photo is at a different time than previous photo
				puts "#{__LINE__} if oneBack || match. oneBack: #{oneBack}. match: #{match} for item: #{item}. DEBUG"
				dupCount = 0 # resets dupCount after having a group of photos in the same second
				fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + userCamCode(fn) + filtered # + fBmark 
				# puts "#{__LINE__}. item: #{item} is at different time as previous.    fileBaseName: #{fileBaseName}"
			end # if oneBack
			
			fileDatePrev = fileDate
			fileExtPrev = fileExt
			# fileBaseNamePrev = fileBaseName
			
			# write to Instructions which can be seen in Mylio and doesn't interfere with Title or Caption
			fileAnnotate(fn, fileDateTimeOriginalstr, tzoLoc, camModel) # was passing fileEXIF, but saving wasn't happening, so reopen in the module?
	
			fnp = fnpPrev = src + fileBaseName + File.extname(fn).downcase # unless #Why was the unless here?
			# puts "Place holder to make the script work. where did the unless come from"
	#       puts "#{__LINE__}. fn: #{fn}. fnp (fnpPrev): #{fnp}. subSec: #{subSec}"
			subSecPrev = subSec.to_s
			File.rename(fn,fnp)
			# Add the processed file to the array so can move unneeded bracket files below
			unneededBracketedFiles << fnp
	
			
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
# 1. Estabish Array.photos
# 2. Rename which may need Array.photos
# 3. Sort and move

puts "\n#{__LINE__}. Copy 'virgin' photos to simulated incoming folder. Adding EXIF in place  so need virgin to start DEV\n"
testPhotos = 'testingClass/incomingTestPhotos'
FileUtils.rm_rf(testPhotos)
# puts value.x # created an error here so script would stop and I could check that folder was deleted and it was
FileUtils.cp_r('testingClass/virginOMcopy2incoming', testPhotos, preserve: true, remove_destination: true ) # preserve to keep timestamp (may not be necesary). cp_r is for directory

lineNum = "#{__LINE__}"
timeNowWas = timeStamp(Time.now, lineNum)
id = 0
photo_array = []
lastPhotoFilename = "OB305994" # use later as starting point

puts "#{__LINE__}. Start of photo processing. First read exif info and write to instructions and optionally to caption for viewing in Mylio
Also for later use in naming photos and putting aside sequence (bracketed) shots contributing to stacked image
Will take a bit of time"
# Dir.each_child(src) do |fn| # can be random order
Dir.each_child(src).sort.each do |fn|
	next if fn == '.DS_Store' # each_child knows about . and .. but not 
	id += 1
  preservedFileName = fn
	# redefine fn
  fn  = src + "/" + fn
	fileEXIF = MiniExiftool.new(fn)
	camModel = fileEXIF.model
	fileType = fileEXIF.fileType
	createDate = fileEXIF.CreateDate
	timeStamp = fileEXIF.TimeStamp
	offsetTimeOriginal = fileEXIF.OffsetTimeOriginal
	# model = fileEXIF.model
	
	fileExt = File.extname(fn).tr(".","").downcase 
	case 
	when fileExt == "mov" # OMDS movie
		fileDateTimeOriginal = fileEXIF.CreateDate
	else 
		fileDateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
	end

	driveMode = fileEXIF.DriveMode 
	if fileType == "MOV" # driveMode == "" # nil doesn't work, niether does blank
		shootingMode = "MOV"
		shotNo = ""
		ileDateTimeOriginal = fileEXIF.CreateDate
	else
		shootingMode = driveMode.split(',')[0] # Focus Bracketing or whatever is before the first comma
		shotNo = driveMode.match(/(\d{1,3})/).to_s.rjust(2, '0')
		fileDateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
	end
	subjectTrackingMode = fileEXIF.AISubjectTrackingMode
	stackedImage = fileEXIF.StackedImage
	afPointDetails = fileEXIF.AFPointDetails
	filterEffect = fileEXIF.FilterEffect
	# focusBracketStepSize = fileEXIF.FocusBracketStepSize # removed as didn't see any use
	fileSubSecTimeOriginal = fileEXIF.SubSecTimeOriginal # no error if doesn't exist and it does not puts in OM
	instructions = fileEXIF.instructions 
	timeZoneOffset = fileEXIF.TimeZoneOffset
	
	# Intermediate values and .mov has to be handled differently
	if fileType == "MOV" # driveMode == "" # nil doesn't work, niether does blank
		shootingMode = "MOV"
		shotNo = ""
		fileDateTimeOriginal = fileEXIF.CreateDate
	else
		shootingMode = driveMode.split(',')[0] # Focus Bracketing or whatever is before the first comma
		shotNo = driveMode.match(/(\d{1,3})/).to_s.rjust(2, '0')
		fileDateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
	end
	
	# Changing one field So Preview and some other Apple apps can open the files. If and when Apple adds OM-1 Mark II, can remove this line. 15.2 Still can't open
	fileEXIF.CameraType2 = "OM-1" #  CameraType2 was 'Unknown (S0121)'

	# parsed values
	# Feedback on what's being read. id, fn, camModel, fileType, stackedImage, driveMode, afPointDetails, focusBracketStepSize, subjectTrackingMode, createDate, offsetTimeOriginal, preservedFileName
	# puts "Line no. #{__LINE__}
	# id: #{id}
	#   fn: #{fn}
	# 	camModel: #{camModel}
	#   fileType: #{fileType}
	#   stackedImage: #{stackedImage}
	#   driveMode: #{driveMode}
	#   afPointDetails: #{afPointDetails}
	#   focusBracketStepSize: #{focusBracketStepSize}
	#   subjectTrackingMode: #{subjectTrackingMode}
	#   createDate: #{createDate}
	#   offsetTimeOriginal: #{offsetTimeOriginal}
	#   preservedFileName: #{preservedFileName}
	# 	The following aren't being used at present, some will be calculated and written to the photo
  #   timeStamp: #{timeStamp}
	#   filterEffect: #{filterEffect}
	#   fileSubSecTimeOriginal: #{fileSubSecTimeOriginal}
	#   instructions: #{instructions} . should be blank for unprocessed photo
	#   timeZoneOffset: #{timeZoneOffset} . should be blank for unprocessed photo
  # " 
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
	# tzoLoc = timeZone(fileDateTimeOriginal, timeZonesFile) # the time zone the picture was taken in, doesn't say anything about what times are recorded in the photo's EXIF. I'm doing this slightly wrong, because it's using the photo's recorded date which could be either GMT or local time. But only wrong if the photo was taken too close to the time when camera changed time zones
	# # puts "#{__LINE__}. #{count}. tzoLoc: #{tzoLoc} from timeZonesFile"
	# 
	# # count == 1 | 1*100 ?  :  puts "."  Just to show one value, otherwise without if prints for each file; now prints every 100 time since this call seemed to create some line breaks and added periods.
	# # Also determine Time Zone TODO and write to file OffsetTimeOriginal	(time zone for DateTimeOriginal). Either GMT or use tzoLoc if recorded in local time as determined below
	# # puts "#{__LINE__}.. camModel: #{camModel}. #{tzoLoc} is the time zone where photo was taken. Script assumes GX8 on local time "
	# # Could set timeChange = 0 here and remove from below except of course where it is set to something else
	# timeChange =  0 # 3600 *  # setting it outside the loops below and get reset each time through. But can get changed
	# # puts "#{__LINE__}. camModel: #{camModel}. fileEXIF.OffsetTimeOriginal: #{fileEXIF.OffsetTimeOriginal}"
	# if camModel ==  "MISC" # MISC is for photos without fileDateTimeOriginal, e.g., movies
	# 	# timeChange = 0
	# 	fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
	# 	# puts "#{__LINE__}. fileDateTimeOriginal #{fileDateTimeOriginal}. timeChange: #{timeChange} for #{camModel} meaning movies. DEBUG"
	# elsif camModel == "iPhone X"  # DateTimeOriginal is in local time
	# 	# timeChange = 0
	# 	# fileEXIF.OffsetTimeOriginal = tzoLoc.to_s # redefined below.
	# 	timeChange = (3600*tzoLoc) # previously had error capture on this. Maybe for general cases which I'm not longer covering
	# 	fileEXIF.OffsetTimeOriginal = "GMT" # say what?
	# 	# puts "#{__LINE__}.. fileDateTimeOriginal #{fileDateTimeOriginal}. timeChange: #{timeChange} for #{camModel}" if count == 1 # just once is enough
	# end # if camModel


	fileEXIF.save # only change so far is imageDescription and instructions
	
	photo_id = "photo-" + id.to_s
	photo_array <<	Photo.new(photo_id, fn, fileExt, camModel, fileType, stackedImage, driveMode, afPointDetails, subjectTrackingMode, createDate, fileDateTimeOriginal, offsetTimeOriginal, preservedFileName)
	# Checking what is stored in stacked image
	# puts "#{id}. Stacked Image: `#{stackedImage}`. shotNo: #{shotNo}. driveMode: #{driveMode}.  Original FileName: #{preservedFileName}" # DEV
end # Dir.each_child(src).sort.each do |fn|
puts "\n#{__LINE__}. Finished adding EXIF info and establishing photo array. If want to see some data for each photo, uncomment two lines above."
# puts photo_array.inspect
# puts "#{__LINE__}. ######## End of Array ##########"
# Renaming. Look at original, not sure what is going on exactly Line 1253
# puts "\n{__LINE__}. Rename [tzoLoc = renamePhotoFiles(…)] the photo files with date and an ID for the camera or photographer (except for the paired jpgs in #{tempJpg}). #{timeNowWas}\n"
puts "\n#{__LINE__}. Rename [tzoLoc = renamePhotoFiles(…)] the photo files with date and an ID for the camera or photographer (except for the paired jpgs FIXME. #{timeNowWas}\n"
# tzoLoc = timeZone(fileDateTimeOriginal, timeZonesFile) # Second time this variable name is used, other is in a method
# puts "\n#{__LINE__}. photo_array: #{photo_array}\n"
renameReturn = renamePhotoFiles(photo_array, mylioStaging, timeZonesFile, timeNowWas, photosRenamedTo, unneededStacksFolder) # This also calls rename which processes the photos, but need tzoLoc value. Negative because need to subtract offset to get GMT time. E.g., 10 am PST (-8)  is 18 GMT


puts "\n#{__LINE__}.  Demo of retrieving info from array"
photo_10 = photo_array.find { |photo| photo.id == "photo-10" }
puts "#{__LINE__}. photo_id: photo-10.  Stacked Image: #{photo_10.stackedImage if photo_10}. photo_10.preservedFileName: #{photo_10.preservedFileName}. "
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
# fileDateTimeOriginal = fileEXIF.CreateDate
# else 
# fileDateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
# end
# 
# if camModel ==  "MISC" # MISC is for photos without fileDateTimeOriginal, e.g., movies
# # timeChange = 0
# fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
# # puts "#{__LINE__}. fileDateTimeOriginal #{fileDateTimeOriginal}. timeChange: #{timeChange} for #{camModel} meaning movies. DEBUG"
# elsif camModel == "iPhone X"  # DateTimeOriginal is in local time
# # timeChange = 0
# # fileEXIF.OffsetTimeOriginal = tzoLoc.to_s # redefined below.
# timeChange = (3600*tzoLoc) # previously had error capture on this. Maybe for general cases which I'm not longer covering
# fileEXIF.OffsetTimeOriginal = "GMT" # say what?
# puts "#{__LINE__}.. fileDateTimeOriginal #{fileDateTimeOriginal}. timeChange: #{timeChange} for #{camModel}" if count == 1 # just once is enough
# end # if camModel
#   

# Instantiate each file on card
# 
# For now assume know where coming from
# src = "/Volumes/Macintosh HD/Users/gscar/Library/Mobile Documents/com~apple~CloudDocs/Documents/Ruby/Photo handling/testingClass/incomingTestPhotos"
# lastPhotoFilename = "OB305994"


# Before made a list of files and copied. Will change with objects
# copySD(srcSD, srcHD, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) if whichOne == "SD"
lineNum = "#{__LINE__} + 1"
timeNowWas = timeStamp(timeNowWas, lineNum)