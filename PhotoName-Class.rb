#!/usr/bin/env ruby
# ruby "/Volumes/Macintosh HD/Users/gscar/Documents/Ruby/Photo handling/PhotoName-Class.rb"
require 'fileutils'
include FileUtils
require 'find'
# require 'yaml'
require "time"
require 'irb' # binding.irb where error checking is desired
require 'mini_exiftool' # `gem install mini_exiftool` have to update for 

class Photo
	
	@@count = 0
	  
	# order by need for sorting and dealing with
  def initialize(id, fn, camModel, fileType, stackedImage, driveMode, afPointDetails, focusBracketStepSize, subjectTrackingMode, createDate, offsetTimeOriginal, preservedFileName)
		
		# Every time a Photo (or a subclass of Photo) is instantiated,
		# we increment the @@count class variable to keep track of how
		# many photos have been created.
		# self.class.increment_count # Invoke the method.
	
		def self.increment_count
			@@count += 1
		end
		
		@id = id
		@fn = fn
		@camModel = camModel
		@camModel = camModel
		@stackedImage = stackedImage
		@driveMode = driveMode
		@afPointDetails = afPointDetails
		@focusBracketStepSize = focusBracketStepSize
		@subjectTrackingMode = subjectTrackingMode
		@createDate = createDate
		@offsetTimeOriginal = offsetTimeOriginal
		@preservedFileName = preservedFileName
  end
	# if focusBracketStepSize.nil?
	#   instructions = "STM: " + subjectTrackingModeOne + ". SM:" + shootingMode
	# else
	#   instructions = "STM: " + subjectTrackingModeOne + ". SM:" + shootingMode + ". FocusBrkStep " + focusBracketStepSize.to_s + " "
	# end
	# 
	# unless stackedImage == "No" # Stacked Image : No or Focus-stacked
	#   instructions = stackedImage + ". " + shootingMode
	# end
	# # write  fileEXIF.instructions here or at 637
	# fileEXIF.instructions = "#{instructions}. #{File.basename(fn,".*")}" # Maybe drop basename 
	
end # class photo


# srcHD       = downloadsFolders + " Drag Photos HERE/" # 
# srcHD = "testingClass/incomingTestPhotos"

# Instantiate each photo
src = "testingClass/incomingTestPhotos"
src = "testingClass/singleTestPhoto"
id = 0
lastPhotoFilename = "OB305994" # use later as starting point
Dir.each_child(src) do |fn|
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
	driveMode = fileEXIF.DriveMode
	subjectTrackingMode = fileEXIF.AISubjectTrackingMode
	focusBracketStepSize = fileEXIF.FocusBracketStepSize
	stackedImage = fileEXIF.StackedImage
	afPointDetails = fileEXIF.AFPointDetails
	filterEffect = fileEXIF.FilterEffect
	focusBracketStepSize = fileEXIF.FocusBracketStepSize
	fileSubSecTimeOriginal = fileEXIF.SubSecTimeOriginal # no error if doesn't exist and it does not puts in OM
	instructions = fileEXIF.instructions 
	timeZoneOffset = fileEXIF.TimeZoneOffset
	# Feedback on what's being read. id, fn, camModel, fileType, stackedImage, driveMode, afPointDetails, focusBracketStepSize, subjectTrackingMode, createDate, offsetTimeOriginal, preservedFileName
	puts "Line no. #{__LINE__}
	id: #{id}
	  fn: #{fn}
		camModel: #{camModel}
	  fileType: #{fileType}
	  stackedImage: #{stackedImage}
	  driveMode: #{driveMode}
	  afPointDetails: #{afPointDetails}
	  focusBracketStepSize: #{focusBracketStepSize}
	  subjectTrackingMode: #{subjectTrackingMode}
	  createDate: #{createDate}
	  offsetTimeOriginal: #{offsetTimeOriginal}
	  preservedFileName: #{preservedFileName}
		The following aren't being used at present, some will be calculated and written to the photo
    timeStamp: #{timeStamp}
	  filterEffect: #{filterEffect}
	  fileSubSecTimeOriginal: #{fileSubSecTimeOriginal}
	  instructions: #{instructions} . should be blank for unprocessed photo
	  timeZoneOffset: #{timeZoneOffset} . should be blank for unprocessed photo
  " 
	photo_id = id.to_s
	photo_id =	Photo.new(id, fn, camModel, fileType, stackedImage, driveMode, afPointDetails, focusBracketStepSize, subjectTrackingMode, createDate, offsetTimeOriginal, preservedFileName)
	p photo_id
	# puts "photo_id: #{photo_id}"
	p photo_id.preservedFileName
	# instantiatePhotos(src, lastPhotoFilename)
end

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

# Instaniate each file on card
# 
# For now assume know where coming from
# src = "/Volumes/Macintosh HD/Users/gscar/Library/Mobile Documents/com~apple~CloudDocs/Documents/Ruby/Photo handling/testingClass/incomingTestPhotos"
# lastPhotoFilename = "OB305994"


# Before made a list of files and copied. Will change with objects
# copySD(srcSD, srcHD, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) if whichOne == "SD"
