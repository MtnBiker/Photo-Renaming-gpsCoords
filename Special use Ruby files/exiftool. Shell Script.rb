#!/usr/bin/env ruby
# THIS GOT TOO MESSY, SO MOVED TO exiftool. Shell Script. Blanks. rb
# Set the PATH to include the Homebrew bin directory
ENV['PATH'] = '/opt/homebrew/bin:' + ENV['PATH']
require "Open3"
puts "system 'ruby -v'. Although I think it's the one in the top right that is what's running in TextMate"
system 'ruby -v'
puts "system 'which exiftool', second line is version:"
system 'which exiftool'
system 'exiftool -ver'
puts "`exiftool -ver`"
`exiftool -ver`
puts "since blank above, backticks not working"
puts "result = %x{exiftool -ver}"
result = %x{exiftool -ver}
puts result
puts "result = %x{exiftool -ver} and puts result works. Although no variable passing"
puts "Preliminary info ===================================================\n\n"

# system("echo *")
# system("echo", "*")

filename = "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"
gsubfilename = filename.gsub(' ', '\\ ')
# puts  "\n#{__LINE__}. exiftool -Camera:DriveMode \"\#{gsubfilename}\":\n"
# `exiftool -Camera:DriveMode "#{gsubfilename}"`
# # puts command
# puts "\n==================================================="

# puts "\n#{__LINE__}. Open3 demo"
# stdout_s, status = Open3.capture2('echo "Foo"')
# puts "#{__LINE__}. stdout_s: #{stdout_s}status: #{status}"
# # puts "\n#{__LINE__}. Open3 in action for #{gsubfilename}"
# # stdout_s, status = Open3.capture2(`exiftool -Camera:DriveMode "#{gsubfilename}"`) # Error: File not found - /Users/gscar/Pictures/_Photo\ Processing\ Folders/Watched\ folder\ for\ import\ to\ Photos/2024.03.25-16.09.59.gs.O.orf
# puts "\n#{__LINE__}. Open3 in action for filename"
# stdout_s, status = Open3.capture2(`exiftool -Camera:DriveMode "#{filename}"`)
# # stdout_s, status = Open3.capture2(`exiftool -Camera:DriveMode "#{gsubfilename}"`)
# puts "stdout_s: #{stdout_s}status: #{status}"

puts "\n#{__LINE__}. Or at least the multi-argument form of system"
system(`exiftool -Camera:DriveMode`,` "#{gsubfilename}"`)
puts "==================================================="

# puts "\nRunning in Command Line:\n"
# result = system 'exiftool -a -u -g2 "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.30-16.49.18.gs.O.orf"'
# puts "#{result}\n==================================================="

puts "\n#{__LINE__}. -EXIF:CreateDate:\n"
system 'exiftool -EXIF:CreateDate "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"'  # This works
puts "==================================================="

puts "\n#{__LINE__}.-Camera:DriveMode:\n"
# system 'exiftool -Camera:DriveMode "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"'
system 'exiftool -Camera:DriveMode "/Users/gscar/Pictures/_Photo+Processing_Folders/Watched_folder_for_import_to_Photos/2024.03.30-16.48.45-1.gs.O.orf"'
puts "\n#{__LINE__}.-Camera:SpecialMode:\n"
# system 'exiftool -Camera:SpecialMode "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"'
system 'exiftool -Camera:SpecialMode "/Users/gscar/Pictures/_Photo+Processing_Folders/Watched_folder_for_import_to_Photos/2024.03.30-16.48.45-1.gs.O.orf"'
puts "Hard coded filename works. Now with underscores"
puts "==================================================="

filename = "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"
filename = "/Users/gscar/Pictures/_Photo+Processing_Folders/Watched_folder_for_import_to_Photos/2024.03.30-16.48.45-1.gs.O.orf"
gsubfilename = filename.gsub(' ', '\\ ')
puts "\n#{__LINE__}. :\n"
system("exiftool", "-Camera:DriveMode", "#{gsubfilename}")
# system(`exiftool -Camera:DriveMode "#{gsubfilename}"`)
puts "==================================================="

puts "\n#{__LINE__}. filename with \\ space hard coded"
puts "\n#{__LINE__}. result = %x{exiftool -Camera:DriveMode "
# filename = "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"
# filename = "~/2024.03.25-16.09.59.gs.O.orf"
result = %x{exiftool -Camera:DriveMode /Users/gscar/Pictures/_Photo\ Processing\ Folders/Watched\ folder\ for\ import\ to\ Photos/2024.03.25-16.09.59.gs.O.orf} # thinks 8 different files, ie, \ not working as expected
puts "\n#{__LINE__}. filename with \\ space. result:\n #{result}" 
puts "==================================================="

# puts "\n#{__LINE__}. Escaped that worked on command line"
# `exiftool -Camera:DriveMode /Users/gscar/Pictures/_Photo\ Processing\ Folders/Watched\ folder\ for\ import\ to\ Photos/2024.03.25-16.09.59.gs.O.orf`
# puts "==================================================="

puts "\n#{__LINE__}. removed blanks in filename"
filename = "/Users/gscar/Pictures/_Photo+Processing_Folders/Watched_folder_for_import_to_Photos/2024.03.30-16.48.45-1.gs.O.orf"
# filename = filename.gsub(' ', '\ ')
puts "\n#{__LINE__}. -Camera:DriveMode for #{filename}:\n"
# `exiftool -Camera:DriveMode #{filename}` # doesn't work
system("exiftool", "-Camera:DriveMode", "#{filename}")
puts "\n#{__LINE__}. -Camera:SpecialMode for #{filename}:\n"
system("exiftool", "-Camera:SpecialMode", "#{filename}")
puts "end no blanks ===================================================\n\n"


# puts "\n#{__LINE__}. gsub to change blanks in filename"
# filename = "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"
# filename = filename.gsub(' ', '\ ')
# puts "\n#{__LINE__}. -Camera:DriveMode for #{filename}:\n"
# `exiftool -Camera:DriveMode #{filename}`
# puts "end gsub ===================================================\n\n"

puts "\n#{__LINE__}. gsub to change blanks in filename per ChatGPT"
filename = "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"
filename = filename.gsub(' ', '\ ')
puts "\n#{__LINE__}. \"exiftool -EXIF:DriveMode #{filename}\""
command = "exiftool -Camera:DriveMode #{filename}"
# command = %x{exiftool -EXIF:DriveMode #{filename}}
puts command
# system 'command' # nothing
`command`
puts "end gsub ChatGPT ===================================================\n\n"

puts "\n#{__LINE__}. filename with \\ space"
filename = "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"
filename = filename.gsub(' ', '\ ')
puts "\n#{__LINE__}. result = %x{exiftool -Camera:DriveMode "
# filename = "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"
# filename = "~/2024.03.25-16.09.59.gs.O.orf"
result = %x{exiftool -Camera:DriveMode /Users/gscar/Pictures/_Photo\ Processing\ Folders/Watched\ folder\ for\ import\ to\ Photos/2024.03.25-16.09.59.gs.O.orf} # thinks 8 different files, ie, \ not working as expected
puts "\n#{__LINE__}. filename with \\ space. result:\n #{result}" 


# puts "With backticks"
# filename = "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"
# `exiftool -EXIF:DriveMode "#{filename}"`
# puts "end with backticks==================================================="
#
# puts "With backticks and file at top level, i.e., no space problems"
# filename = "2024.03.25-16.09.59.gs.O.orf"
# `exiftool -EXIF:DriveMode ~/2024.03.25-16.09.59.gs.O.orf`
# puts "==================================================="
# system 'exiftool -EXIF:DriveMode "/Users/gscar/2024.03.25-16.09.59.gs.O.orf"'
# puts "end with file at top level==================================================="
#
# filename = "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"
# result = `exiftool -EXIF:DriveMode '#{filename}' 2>&1`
# puts result

# filename = "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"
# command = "exiftool -EXIF:DriveMode '#{filename}'"
# puts "Running command: #{command}"
# system(command)
# Result:
# Running command: exiftool -EXIF:DriveMode '/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf'
# puts "==================================================="
# filename = "/Users/gscar/Pictures/_Photo Processing Folders/Watched folder for import to Photos/2024.03.25-16.09.59.gs.O.orf"
# command = "exiftool -EXIF:DriveMode '#{filename}'"
# puts "Running command: #{command}"
# success = system(command)
# puts "Command executed successfully" if success
# puts success