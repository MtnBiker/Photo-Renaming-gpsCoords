#!/usr/bin/env ruby
#
#  Created by Greg Scarich on 2007-06-20.
#  Copyright (c) 2007. All rights reserved.

# Read EXIF fields, but doesn't seem to read IPTC fields

# Didn't used to need this, but some PATH is missing
ENV['PATH'] = '/opt/homebrew/bin:' + ENV['PATH']

require 'rubygems'
require 'mini_exiftool' # a wrapper for the Perl ExifTool 
require 'time'
require 'fileutils'
include FileUtils
# require 'puts_debugger' # puts_debugger # gem seems to be found, but using doesn't  > NoMethodError: undefined method ‘puts_debugger’ for main:Object

fn = "/Users/gscar/Documents/◊ Pre-trash/galleryTest/Fonts Point Badlands Dry Stream.jpg"
fn = "/Volumes/Daguerre/_Download folder/_imported-archive/P114-GX8/P1140931.RW2"
fn = "/Users/gscar/Mylio/Mylio Main Library Folder/2024/OM-1-2024/2024.04.09-14.29.04.gs.O.jpg"
# fn = "/Users/gscar/Mylio/Mylio Main Library Folder/2024/OM-1-2024/2024.04.14-12.28.57.gs.O.jpg" # LiveND
fn = "/Users/gscar/Mylio/Mylio Main Library Folder/2024/OM-1-2024/2024.04.10-09.30.54.gs.O.jpg" # out of focus
fn = "/Volumes/OM SYSTEM/DCIM/100OMSYS/O4304077.JPG"

puts "fn: #{fn}"
puts "All readable MiniExifTool fields,i.e., MiniExiftool.new(fn)"
puts
photo = MiniExiftool.new(fn)
puts "photo: #{photo}"
puts
photo.tags.sort.each do |tag|
  puts "#{tag}:         #{photo[tag]}"
end
puts

# test write to Title. This worked. Ran again to confirm
# photo.title = "test"
# photo.save

puts "At #{Time.now}"
puts "Camera is recording in the time zone it's set for and has no knowledge of time zone it's in, but Ruby assumes the photo is in the time zone of the computer at the moment "
puts "Confirming terminology of EXIF dates for MiniExifTool for"
puts "fn: #{fn}"
# puts "Source: #{photo.source}" # debugging was nil
# puts "File Source: #{photo.filesource}" # Digital Camera
puts "TimeStamp:                #{photo.TimeStamp} of class #{photo.TimeStamp.class}. For GX8 seems to account for time zone in that TimeStamp is UTM if a zone is set for local time"
puts "dateTimeOriginal:         #{photo.dateTimeOriginal}" #         This works for Canon.avi, but not Minolta.mov
puts "SubSecDateTimeOriginal    #{photo.SubSecDateTimeOriginal}"
puts "createDate:               #{photo.createDate} of class #{photo.createDate.class}" #        For Minolta.mov since dateTimeOriginal doesn't work. Probably less accurate, but seems like best option
puts "SubSecCreateDate          #{photo.SubSecCreateDate}"
puts
puts "ModifyDate:               #{photo.ModifyDate}"
puts "SubSecModifyDate          #{photo.SubSecModifyDate}"  
puts "FileModifyDate:           #{photo.FileModifyDate}" #"          Note can be 1 sec earlier or later than Modify Date
puts
puts "FileInodeChangeDate       #{photo.FileInodeChangeDate}"
puts "FileAccessDate            #{photo.FileAccessDate}"

puts "\nIf aware of time zone camera is in. GX8 is all null"
puts "TimeZoneOffset            #{photo.TimeZoneOffset}. 1. The time zone offset of DateTimeOriginal from GMT in hours, 2. If present, the time zone offset of ModifyDate" 
puts "OffsetTime                #{photo.OffsetTime}.          time zone for ModifyDate"
puts "OffsetTimeOriginal        #{photo.OffsetTimeOriginal}.  time zone for DateTimeOriginal"
puts "OffsetTimeDigitized	      #{photo.OffsetTimeDigitized}. time zone for CreateDate"

subjectTrackingMode = photo.AISubjectTrackingMode
puts "\nAISubjectTrackingMode     #{subjectTrackingMode}"
if subjectTrackingMode.nil?
  puts # AISubjectTrackingMode is nil
else
  puts "AISubjectTrackingMode.split[0].chop     #{subjectTrackingMode.split[0].chop}"
  puts "AISubjectTrackingMode.split(';')[0]     #{subjectTrackingMode.split(';')[0]}"
end
driveMode = photo.DriveMode
puts "\ndriveMode = photo.DriveMode  #{driveMode}"
if driveMode.nil?
  puts "DriveMode is nil"
else
  puts "driveMode.split(';')[0]     #{photo.DriveMode.split(';')[0]}"
  puts "driveMode.split(';')[1]     #{photo.DriveMode.split(';')[1]}"
end
stackedImage = photo.StackedImage
puts "\nstackedImage = photo.StackedImage: #{stackedImage}"
# A test of logic
if stackedImage != "No"
  puts "#{__LINE__}. StackedImage: #{stackedImage}"
else
  puts "#{__LINE__}. StackedImage: #{stackedImage} [or is nil] and will not be written to instructions"
end

# puts "\nPossible time zone determination. (CreateDate - TimeStamp)/3600:"
# photo.DateTimeUTC doesn't exist? and photo.CreateDate can't be divided
# timeZoneOffset =  (photo.CreateDate - photo.TimeStamp)/3600 # photo.CreateDate = 
# puts "photo.DateTimeUTC: #{photo.DateTimeUTC}"
# timeZoneOffset =  (photo.CreateDate - photo.DateTimeUTC)/3600
timeZoneOffset = ""

# puts "\ntimeZoneOffset: #{timeZoneOffset} of class: #{timeZoneOffset.class}. Except can't calculate timeZoneOffset"
# puts "where timeZoneOffset = (photo.CreateDate - photo.TimeStamp)/3600"
# puts "WorldTimeLocation: #{photo.WorldTimeLocation}" # TimeInfo, PanasonicDateTime are null. WorldTimeLocation = Home eg
# puts "For GX8, this is using the fact that time is set to local, but the time zone can be specified"
#
# puts "\nTrying to strip time zone info"
# puts "createDate.ctime:         #{photo.createDate.ctime} and this apparently does it"
#
# puts "\nCan a time zone be assigned?"
# puts "Time.at(1582721899, in: \"+09:00\") "
# createDateToI = photo.createDate.to_i
# puts "\nphoto.createDate.to_i: #{createDateToI} of class #{createDateToI.class} and it's an integer"
# # createDateToIZ = Time.at(createDateToI, in "+09:00")
# puts "Time.at(createDateToI, in \"+09:00\"): can't do"

# puts "\nSince camera doesn't know about time zones, probably best to parse the response and convert back to the time zone desired"
# createDateToArray = photo.createDate.to_a
# puts "photo.createDate.to_a: #{createDateToArray}. [sec, min, hour, day, month, year, wday, yday, isdst, zone]"
# tz = "+09:00" # Forcing time zone, but for photos should be able to read from time zones file except I don't always get it right
# puts "Syntax: Time.new(2002, 10, 31, 2, 2, 2, \"+02:00\") #=> 2002-10-31 02:02:02 +0200"
# cda = createDateToArray # just so easier to read
# createDateToTz = Time.new(cda[5], cda[4], cda[3], cda[2], cda[1], cda[0], tz)
# puts "Time.new(cda[5], cda[4], cda[3], cda[2], cda[1], cda[0], tz): \n#{createDateToTz} \nwhere cda = createDateToArray = photo.createDate.to_a and tz: #{tz} set manually, and createDateToTz.class: #{createDateToTz.class}"
# puts "Stripping incorrect or arbitrary time zone from createDate, then adding the correct one"
### If set to local time TimeStamp is GMT


# puts "\n\nUNIX dates related to file"
# puts "File.mtime (last modified) :   #{File.mtime(fn)}"
# puts "File.ctime (status changed):   #{File.ctime(fn)}"
# puts "File.atime (last accessed) :   #{File.atime(fn)}"

# puts
# puts ".minoltaDate Time: Don't know how to call them "        #{photo.MinoltaDate} #{MinoltaTime} # didn't work
# puts "AVI: dateTimeOriginal and FileModifyDate are the same for .avi. (Need to confirm whether they are shooting time or some other time)"
# puts "AVI: create date is blank"
# puts "Minolta .mov: "



# puts "Tried and didn't work: dateTime, FileDate, FileDateTime, "

=begin
photo = MiniExiftool.new(fn)
 puts "Konica-Minolta MOV   MIMEType #{photo.mimetype}"
puts

tagCount = 0
puts "All writable MiniExiftool tags for #{fn}"
puts
tagArray = MiniExiftool.new(fn)
MiniExiftool.writable_tags.sort.each do |tag|
  puts "#{tag}:         #{tagArray[tag]}"
  tagCount += 1
end
puts
puts "#{tagCount} tags for this file #{fn}" 
puts "Extension:  #{File.extname(fn)}"
puts "FileType:    #{photo.FileType(fn)}"
puts "MIMEType:    #{photo.MIMEType}"

=end
