#!/usr/bin/env ruby
# Was exiftool. Shell Script.rb. Was getting too messy, so started over here with comments from
# https://stackoverflow.com/questions/78257612/how-to-introduce-a-filename-into-shell-script-in-ruby-script
# Set the PATH to include the Homebrew bin directory
ENV['PATH'] = '/opt/homebrew/bin:' + ENV['PATH']
require "Open3"
puts "#{__LINE__}. system 'ruby -v'. Although I think it's the one in the top right that is what's running in TextMate"
system 'ruby -v'
puts "#{__LINE__}. system 'which exiftool':"
system 'which exiftool'
puts "Preliminary info ===================================================\n\n"

puts "#{__LINE__}. Don't build a command line as a string. For example: system('exiftool', '-Camera:DriveMode', filename). Similar approaches work with Open3. If you do it like that then you won't launch a shell and you won't have to deal with the shell's quoting and escaping problems, see the docs I linked to above.\n, if you give at least one argument besides the program name to the function, the shell is not invoked."

filename = "//Volumes/Daguerre/_Download folder/Latest Processed photos-Import to Mylio/2024.03.30-16.48.45.gs.O.orf"

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
filename = "/Volumes/Daguerre/_Download folder/_imported-archive/O3301583.ORF"
driveMode, whatelse = system('exiftool', '-Camera:DriveMode', filename)
specialMode = system('exiftool', '-Camera:SpecialMode', filename)
puts "whatelse: #{whatelse}"
puts "driveMode: #{driveMode}. specialMode: #{specialMode}. driveMode.class: #{driveMode.class}. "

puts "\n#{__LINE__}. Focus bracketing:"
filename = "/Volumes/Daguerre/_Download folder/_imported-archive/O4021626.JPG"
driveMode, whatelse = system('exiftool', '-Camera:DriveMode', filename)
specialMode = system('exiftool', '-Camera:SpecialMode', filename)
puts "whatelse: #{whatelse}"
puts "driveMode: #{driveMode}. specialMode: #{specialMode}. driveMode.class: #{driveMode.class}. "

puts "\n#{__LINE__}. High speed sequential:"
filename = "/Volumes/Daguerre/_Download folder/_imported-archive/O4021705.ORF"
driveMode = system('exiftool', '-Camera:DriveMode', filename)
specialMode = system('exiftool', '-Camera:SpecialMode', filename)
puts "driveMode: #{driveMode}. specialMode: #{specialMode}."


puts "\n\nGetting needed info"

puts"\n Using: r, w = IO.pipe
system(\"ls\", out: w)
w.close
output = r.read "
puts "\n#{__LINE__}. Focus bracketing:"
filename = "/Volumes/Daguerre/_Download folder/_imported-archive/O4021612.ORF"
# driveMode = system('exiftool', '-Camera:DriveMode', filename)

# Reading driveMode
r, w = IO.pipe
system('exiftool', '-Camera:DriveMode', filename, out: w)
w.close
driveMode = r.read

# specialMode = system('exiftool', '-Camera:SpecialMode', filename)
r, w = IO.pipe
system('exiftool', '-Camera:SpecialMode', filename, out: w)
w.close
specialMode = r.read

puts "\n#{__LINE__}\ndriveMode: #{driveMode}\nspecialMode: #{specialMode}"

