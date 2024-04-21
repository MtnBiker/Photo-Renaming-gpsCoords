#!/usr/bin/env ruby
ENV['PATH'] = '/opt/homebrew/bin:' + ENV['PATH'] #
require 'rubygems' # # Needed by rbosa, mini_exiftool, and maybe by appscript,  
#require 'appscript' # needed by Appscript
#include Appscript # aka rb-appscript
#require 'rbosa' # probably don't want both rbosa and Appscript
require 'mini_exiftool' # a wrapper for the Perl ExifTool 
#require 'time'
#require 'fileutils'
#include fileutils
#require 'find'
#  Created by Greg Scarich on 2007-07-11.  Copyright (©) 2007. All rights reserved.


# fn = "/Volumes/Daguerre/_Download folder/Latest Processed photos-Import to Mylio/2019.08.05-10.49.54.gs.P.jpg"
fn = "/Users/gscar/Mylio/Mylio Main Library Folder/2024/OM-1-2024/2024.04.20-12.27.58.gs.O.jpg"
tagCount = 0 # existing
totalTagCount = 0
puts "All writable MiniExiftool tags for #{fn}"
puts
tagArray = MiniExiftool.new(fn)

# Only tags with data
MiniExiftool.writable_tags.sort.each do |tag|
  if tagArray[tag]
    puts "#{tag}:         #{tagArray[tag]}"
    tagCount += 1
  end
  totalTagCount += 1
end

# Too see all tags
# MiniExiftool.writable_tags.sort.each do |tag|
#   puts "#{tag}:         #{tagArray[tag]}"
#   tagCount += 1
# end


puts
# puts "Always says 1637 tags, so maybe can't write to all formats (movies, MRW),"
# puts "probably just what MiniExiftools know about. Try it"
puts "#{tagCount} tags written for #{totalTagCount} possible tags for this file #{fn}" 
puts "Extension:  #{File.extname(fn)}"
puts "FileType:    #{tagArray.FileType(fn)}"
puts "MIMEType:    #{tagArray.MIMEType}"

puts
puts "Possible tags to use for GVS. Note existing file for a file straight from camera: 
AeProjectLinkRenderTimeStamp:         
AltTimecode:         
AltTimecodeTimeFormat:         
AltTimecodeTimeValue:         
AltTimecodeValue:         
CaptionsDateTimeStamps:         
CreateDate:         2019-07-26 16:02:44 -0700
CreationDate:         
CreationTime:         
ateTime:         
DateTimeDigitized:         
DateTimeOriginal:         2019-07-26 16:02:44 -0700
DateTimeStamp:         
DateTimeUTC:         
DigitalCreationDate:         
DigitalCreationTime:         
OffsetTime:         
OffsetTimeDigitized:         
OffsetTimeOriginal:         
OriginalCreateDateTime:         
PanasonicDateTime:         
RelativeTimestamp:         
RelativeTimestampScale:         
RelativeTimestampValue:         
SubSecCreateDate:         2019-07-26 16:02:44 -0700
SubSecDateTimeOriginal:         2019-07-26 16:02:44 -0700
SubSecModifyDate:         2019-07-26 16:02:44 -0700
TimeStamp:         2019-07-26 23:02:44 -0700
TimeZone:         
TimeZoneCity:         
TimeZoneCode:         
TimeZoneInfo:         
TimeZoneOffset:         
WorldTimeLocation:         Home
CreateDate:         2019-07-26 16:02:44 -0700
CreationDate:         
CreationTime:         
DateTimeOriginal:         2019-07-26 16:02:44 -0700
DateTimeStamp:         
DateTimeUTC:         
PSDateStamp:         
GPSDateTime:         
GPSDestBearing:         
GPSDestBearingRef:         
GPSDestDistance:         
GPSDestDistanceRef:         
GPSDestLatitude:         
GPSDestLatitudeRef:         
GPSDestLongitude:         
GPSDestLongitudeRef:         
GPSDifferential:         
GPSHPositioningError:         
GPSImgDirection:         
GPSImgDirectionRef:         
GPSLatitude:         
GPSLatitudeRef:         
GPSLongitude:         
GPSLongitudeRef:         
GPSLongtitude:         
GPSMapDatum:         
GPSMeasureMode:         
GPSProcessingMethod:         
GPSSatellites:         
GPSSpeed:         
GPSSpeedRef:         
GPSStatus:         
GPSString:         
GPSTimeStamp:         
GPSTrack:         
GPSTrackRef:         
GPSVersionID:         
ModifyDate:         2019-07-26 16:02:44 -0700"
