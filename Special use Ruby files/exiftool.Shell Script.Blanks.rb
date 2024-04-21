#!/usr/bin/env ruby
# Was exiftool. Shell Script.rb. Was getting too messy, so started over here with comments from
# https://stackoverflow.com/questions/78257612/how-to-introduce-a-filename-into-shell-script-in-ruby-script
# Set the PATH to include the Homebrew bin directory
ENV['PATH'] = '/opt/homebrew/bin:' + ENV['PATH'] # Doesn't work in TM on macMini without this. Does work on macMini command line with or without this and `which exiftool` is the same: /opt/homebrew/bin/exiftool
require "Open3"
puts "#{__LINE__}. system 'ruby -v'. Although I think it's the one in the top right that is what's running in TextMate"
system 'ruby -v'
puts "#{__LINE__}. system 'which exiftool':"
system 'which exiftool'
puts "Preliminary info ===================================================\n\n"

puts "#{__LINE__}. Don't build a command line as a string. For example: system('exiftool', '-Camera:DriveMode', filename). Similar approaches work with Open3. If you do it like that then you won't launch a shell and you won't have to deal with the shell's quoting and escaping problems, see the docs I linked to above.\n, if you give at least one argument besides the program name to the function, the shell is not invoked."

filename = "/Users/gscar/Mylio/Mylio Main Library Folder/2024/OM-1-2024/2024.04.20-12.27.58.gs.O.jpg"

system('exiftool', '-Camera:DriveMode', filename)

system('exiftool', '-Camera:SpecialMode', filename)

# Thank you both @mu is too short  @Amadan. To summarize for my benefit:
#
# `system('exiftool', '-Camera:DriveMode', filename)`. Doesn't launch a shell and you won't have to deal with the shell's quoting and escaping problems.
#
# If you give at least one argument besides the program name to the function, the shell is not invoked.
#
# Although I have to admit I don't understand why this avoids shell's escaping problems, but getting through shell, subshell, command_line. In other words, many words I don't fully comprehend https://ruby-doc.org/3.3.0/Kernel.html#method-i-system


puts "\n\nShot types in OM. This is the return from system, see below ===================================================\n"
puts "\n#{__LINE__}. Regular photo:"
filename = "/Volumes/Daguerre/_Download folder/_imported-archive/0100-OM-1/O3[2024.03]-OM/O3301583.ORF"
driveMode, whatelse = system('exiftool', '-Camera:DriveMode', filename)
specialMode = system('exiftool', '-Camera:SpecialMode', filename)
stackedImage  = system('exiftool', '-Camera:StackedImage', filename)
puts "driveMode: #{driveMode}. specialMode: #{specialMode}. stackedImage: #{stackedImage}."
# puts "driveMode: #{driveMode}. specialMode: #{specialMode}. driveMode.class: #{driveMode.class}. "

puts "\n#{__LINE__}. Focus bracketing:"
filename = "/Volumes/Daguerre/_Download folder/_imported-archive/0100-OM-1/O40-ProCapture test-delete?/O4021626.JPG"
driveMode, whatelse = system('exiftool', '-Camera:DriveMode', filename)
specialMode = system('exiftool', '-Camera:SpecialMode', filename)
stackedImage  = system('exiftool', '-Camera:StackedImage', filename)
# puts "whatelse: #{whatelse}"
puts "driveMode: #{driveMode}. specialMode: #{specialMode}. stackedImage: #{stackedImage}. driveMode.class: #{driveMode.class}. "

puts "\n#{__LINE__}. High speed sequential:"
filename = "/Users/gscar/Mylio/Mylio Main Library Folder/2024/OM-1-2024/2024.04.05-15.23.34-38.gs.O.jpg"
driveMode = system('exiftool', '-Camera:DriveMode', filename)
specialMode = system('exiftool', '-Camera:SpecialMode', filename)
stackedImage  = system('exiftool', '-Camera:StackedImage', filename)
puts "driveMode: #{driveMode}. specialMode: #{specialMode}. stackedImage: #{stackedImage}."


puts "\n#{__LINE__}. LiveND:"
filename = "/Users/gscar/Mylio/Mylio Main Library Folder/2024/OM-1-2024/2024.04.14-12.28.57.gs.O.jpg"
driveMode = system('exiftool', '-Camera:DriveMode', filename)
specialMode = system('exiftool', '-Camera:SpecialMode', filename)
stackedImage  = system('exiftool', '-Camera:StackedImage', filename)
puts "driveMode: #{driveMode}. specialMode: #{specialMode}. stackedImage: #{stackedImage}."
puts "#{__LINE__}. LiveND: #{filename}"

puts "\nStacked image must mean stacked in camera, not a frame of a stacked image. Don't have lens to do stacked image in camera now. Just looking for possible values to use in sorting photos into categories"

puts "\n\nGetting needed info"

puts"\n Using: r, w = IO.pipe
system(\"ls\", out: w)
w.close
output = r.read "
puts "\n#{__LINE__}. Focus bracketing:"
filename = "/Volumes/Daguerre/_Download folder/_imported-archive/0100-OM-1/O40-Focus Bracketing-delete?/O4021612.ORF"
driveMode = system('exiftool', '-Camera:DriveMode', filename)

# Reading driveMode
r, w = IO.pipe
system('exiftool', '-Camera:DriveMode', filename, out: w)
w.close
driveMode = r.read
# puts "driveMode result: #{driveMode} for bracketed photo??."

# specialMode = system('exiftool', '-Camera:SpecialMode', filename)
r, w = IO.pipe
system('exiftool', '-Camera:SpecialMode', filename, out: w)
w.close
specialMode = r.read

puts "\n#{__LINE__}\ndriveMode: #{driveMode}\nspecialMode: #{specialMode}"

puts "\nYet another test"
filename = "/Users/gscar/Mylio/Mylio Main Library Folder/2024/GX8-2024/2024.02.16-13.16.42.gs.P_display.jpg"
r, w = IO.pipe
system('exiftool -api geolocation', '"-geolocation*" ', filename, out: w)
w.close
geoloc = r.read
puts "\n#{__LINE__}. geoloc: #{geoloc}"

