#!/usr/bin/env ruby
# Would be hard to develop. Need to check if Preview overlaps Master and finally is it in the libary that I have.
# Would this be done with database or Arrays
#  Might be easier to just look for missing files
require 'fileutils'
include FileUtils
require 'find'
require 'mini_exiftool'

def lineNum()
  caller_infos = caller.first.split(":")
  # Note caller_infos[0] is file name
  caller_infos[1]
end # line numbers of this file, useful for debugging and logging info to progress screen

def ignoreNonFiles(item) # invisible files that shouldn't be processed
  item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon '
  # This is true when it should not be processed i.e. next if ignoreNonFiles(item) == true
  # next if ignoreNonFiles(item) == true # how to use this
end

# a = %w( cats dogs monkeys frogs)
# b = %w( cats dogs monkeys fish birds  )
# puts "a: #{a}"
# puts "b: #{b}"
#
# puts "not in both"
# puts (a | b) - (a & b)
#
# puts
#
# puts "What's in b that's not in a #{b - a}"
# puts
# puts "What's in a that's not in b #{a-b}"
i = 0
j = 0
src = "/Volumes/Knobby Aperture II/_Pre-trash Knobby Aperture II/Knobby 2013+.aplibrary/"
puts "src: #{src}"
# fileArray = Dir.entries(src) #  # Doesn't dive in
# Dir.chdir(src)
# fileArray = Dir.glob("*") # doesn't dive in
fileArray = Find.find(src) do |fn|
  # if File.file?(fn) && fileSize = File.size(fn) > 1000000 # only files passed
  fileSize = File.size(fn) # .mov in Aperture generates a small .jpg
  extName = false
  extName = true if File.extname(fn) == ".jpg" || File.extname(fn) == ".mrw" || File.extname(fn) == ".rw2" ||  File.extname(fn) == ".png"
  if File.file?(fn) && fileSize > 10000 && extName# 
    # Ignore files with _face (Aperture creates for each face in a photo), but this contains .jpg so have to screen out
    # Only .jpg, .png, .rw2, .mrw, .mov
  # if fileSize > 10000 # only working on files NOT at least I get more files this way. Using size to screen for images, but maybe could use extensions, but have to make srure do't make
  # Some thumbnails are 1024 by which may be useful if missing 
# puts "#{lineNum} src: #{src}\nfileArray: #{fileArray}"
    # i += 1
    
    puts "#{lineNum}. #{i += 1}. fileSize: #{fileSize} bytes of  #{fn}" # Gets larger Previews. So have to sort out Previews if the full size file exists
  # else # not a file or too small or not an image
    # puts "#{lineNum}. #{j += 1}. Not an image or too small #{fn}"
    # puts "#{lineNum}. #{j += 1}. Not an image or too small #{fn}" if extName # only Previews 
  end
end
# Dir.foreach(src) do |item| # for each photo file
#   next if ignoreNonFiles(item) == true # skipping file when true, i.e., not a file
#   # puts "#{lineNum}. #{item} will be renamed. " # #{timeNowWas = timeStamp(timeNowWas)}
#   fn = src + item # long file name
#   #Minimum file size
#   fileSize = File.size(fn)
#   puts "#{lineNum}. fileSize: #{fileSize} bytes of #{fn}"
#
#   # fileEXIF = MiniExiftool.new(fn) # used several times
# end
