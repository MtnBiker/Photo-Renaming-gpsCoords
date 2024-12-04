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
	
	attr_accessor :id, :fn, :camModel, :fileType, :stackedImage, :driveMode, :afPointDetails, :subjectTrackingMode, :createDate, :offsetTimeOriginal, :preservedFileName
	# order by need for sorting and dealing with
  def initialize(id, fn, camModel, fileType, stackedImage, driveMode, afPointDetails, subjectTrackingMode, createDate, offsetTimeOriginal, preservedFileName)
		
# The counting needs some work, where did I get it from
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
		@camModel = camModel
		@stackedImage = stackedImage
		@driveMode = driveMode
		@afPointDetails = afPointDetails
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

# Adding each file to Array photos
# temp src until determine using. Full path needed to run from arbitrary place in iTerm. Relative works in Nova
src = "/Users/gscar/Documents/Ruby/Photo handling/testingClass/incomingTestPhotos/" # Stacked w/ and w/o a stacked image, HHHR, THR, 
# src = "/Volumes/Daguerre/_Download folder/_imported-archive/OM-1/OB[2024.11]-OM/" # 308 photos
# src = "/Volumes/Daguerre/_Download folder/_imported-archive/OM-1/OA[2024.10]-OM/" # 476 photos
# src = "testingClass/singleTestPhoto"
id = 0
photos = []
lastPhotoFilename = "OB305994" # use later as starting point
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
	driveMode = fileEXIF.DriveMode
	subjectTrackingMode = fileEXIF.AISubjectTrackingMode
	stackedImage = fileEXIF.StackedImage
	afPointDetails = fileEXIF.AFPointDetails
	filterEffect = fileEXIF.FilterEffect
	# focusBracketStepSize = fileEXIF.FocusBracketStepSize # removed as didn't see any use
	fileSubSecTimeOriginal = fileEXIF.SubSecTimeOriginal # no error if doesn't exist and it does not puts in OM
	instructions = fileEXIF.instructions 
	timeZoneOffset = fileEXIF.TimeZoneOffset
	# parsed values
	shotNo = driveMode.match(/(\d{1,3})/).to_s.rjust(2, '0')
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
	
	# 
	imageDescription = "" # so not carried over from previous photo
	# Only put in if value is present
	if stackedImage != "No" # Always a value. Don't need to see No
		imageDescription = stackedImage + " [StackedImage]. "
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
	fileEXIF.description = imageDescription
	# end imageDescription
	fileEXIF.save # only change so far is imageDescription
	
	photo_id = "photo-" + id.to_s
	photos <<	Photo.new(photo_id, fn, camModel, fileType, stackedImage, driveMode, afPointDetails, subjectTrackingMode, createDate, offsetTimeOriginal, preservedFileName)
	# p photo_id
	# puts "photo_id: #{photo_id}"
	# puts "id: #{photo_id}. preservedFileName: #{photo_id.preservedFileName}"
	# Checking what is stored in stacked image
	puts "#{id}. Stacked Image: `#{stackedImage}`. shotNo: #{shotNo}. driveMode: #{driveMode}.  preservedFileName: #{preservedFileName}"
end

puts "\n#{__LINE__}.  Demo of retrieving info from array"
photo_10 = photos.find { |photo| photo.id == "photo-10" }
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

# Instaniate each file on card
# 
# For now assume know where coming from
# src = "/Volumes/Macintosh HD/Users/gscar/Library/Mobile Documents/com~apple~CloudDocs/Documents/Ruby/Photo handling/testingClass/incomingTestPhotos"
# lastPhotoFilename = "OB305994"


# Before made a list of files and copied. Will change with objects
# copySD(srcSD, srcHD, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) if whichOne == "SD"
