#!/usr/bin/env ruby

src = "/Volumes/Daguerre/_Download folder/_imported-archive/P116-GX8/"
src = "/Users/gscar/Doc iMac only/◊ Pre-trash/test/"

fileCount = 0
deleteCount = 0
def lineNum() # Had to move this to above the first call or it didn't work. Didn't think that was necessary
  caller_infos = caller.first.split(":")
  # Note caller_infos[0] is file name
  caller_infos[1]
end # line numbers of this file, useful for debugging and logging info to progress screen

puts "Removing duplicates usually caused by running PhotoName… script several times. If file name contains '-1, -2 or -3' it will be deleted"
# Removing duplicate photos from rerunning of main script
# Anything with a -1 or -2 is removed

# Typical file name P1160273-1

Dir.chdir(src) # needed for glob
Dir.glob("P*") do |item| 
  fileCount += 1
  fileBasename = File.basename(item,".*")
  puts "#{lineNum}. #{fileBasename}"

# Crude, but this is little used
  if fileBasename.include? "-1"
     puts "#{lineNum}. Basename includes '-1 and will be deleted'"
     File.delete(item)
     deleteCount += 1
  end

  if fileBasename.include? "-2"
     puts "#{lineNum}. Basename includes '-2' and will be deleted"
     File.delete(item)
     deleteCount += 1
  end

  if fileBasename.include? "-3"
     puts "#{lineNum}. Basename includes '-3' and will be deleted"
     File.delete(item)
     deleteCount += 1
  end


end

puts "#{lineNum} #{deleteCount} duplicate photos were deleted from an original #{fileCount} photos"