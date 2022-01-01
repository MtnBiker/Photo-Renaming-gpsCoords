#!/usr/bin/env ruby
require 'mini_exiftool'
require 'find'

# Makes no sense in doing Previews since they can be regenerated and it's unlikely they are used for much related to this
# Right now specifying Masters and Previews separately. If do the whole Library need to exclude Thumbnails.

# src = "/Volumes/Knobby Aperture Two/Aperture Libraries/Indonesia 2016.Sierra.aplibrary/Previews/" # Done
src = "/Volumes/Knobby Aperture Two/Aperture Libraries/Indonesia 2016.Sierra.aplibrary/Masters/" # Done
src = "/Volumes/Knobby Aperture Two/Aperture Libraries/West Africa 2006–8.Sierra.aplibrary/Masters/" # In progress—but there was nothing in Title, i.e., before I did that.


# Masters didn't have any of the three fields
i = 0

puts src

def ignoreNonFiles(item) # invisible files that shouldn't be processed
  item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon ' or File.directory?(item)
  # This is true when it should not be processed i.e. next if ignoreNonFiles(item) == true
end
def lineNum()
  caller_infos = caller.first.split(":")
  # Note caller_infos[0] is file name
  caller_infos[1]
end

Find.find(src) do |item|
  next if ignoreNonFiles(item) == true # skipping file when true
  i += 1

  fileEXIF = MiniExiftool.new(item)
  
  # Leaving one puts, but commented others out hoping would speed things up
  puts "\n#{lineNum}. #{i}. #{File.basename(item,".*")}. ObjectName: #{fileEXIF.ObjectName}. ≠ Title: #{fileEXIF.title} | Caption[Abstract]: #{fileEXIF.CaptionAbstract} | Source: #{fileEXIF.source}"

# Moving title to source. This works
# puts "#{lineNum}. If there is a period after this, the title will be copied to source: #{fileEXIF.source.to_s[-4]}"
  if fileEXIF.title.to_s.length > 2 && fileEXIF.title.to_s[-4] =="."  # in other words if it exists
    # In case this gets run twice we need to see if title is really the file basename, one check might be to see if the fourth to last character is a period (unlikely if title has been changed to caption)
    fileEXIF.source = fileEXIF.title
    
    fileEXIF.title = "" # This shouldn't be needed if the next step works correctly.
    # puts "#{lineNum}. Moving title (file name) to source (little used field #{fileEXIF.title} to #{fileEXIF.source})"
  end

  # Write Caption to Title. Caption is CaptionAbstract. Title is ObjectName or title (seem to be different things)
  # Generally no Captions in the Masters. Only thing to be done is move Title to Source
  if fileEXIF.CaptionAbstract.to_s.length > 2
    # Not quite sure which is which, i.e., ObjectName and Title are the same thing in some places (Aperture?)
    fileEXIF.ObjectName = fileEXIF.title = fileEXIF.CaptionAbstract
    # puts "#{lineNum}. #{i}. #{item}. Writing Caption (CaptionAbstract) to Title #{fileEXIF.CaptionAbstract}"
  else
    fileEXIF.title = "" # to wipe out the old filename that was there
    # puts "#{lineNum}. #{i}. #{item}. Writing blank to Title"
  end
  fileEXIF.save
end
