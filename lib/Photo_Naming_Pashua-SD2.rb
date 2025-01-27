#  Created by Greg Scarich on 2007-07-30.  Heavily changed 2012.12.28
# require 'Pashua' # for GUI
require File.expand_path(File.join(File.dirname(__FILE__), 'Pashua'))

include Pashua

# This code is based on that contributed by Mike Hall to Pashua. It uses a module
# Pashua.rb, which is expected to be located either in this script's
# parent directory or in some standard Ruby search path. Please note
# the comments at the top of Pashua.rb.
# http://www.bluem.net/downloads/pashua_en/

# This file is called first. 
#  This is revised to eliminate the old cruft


def pPashua2(srcPhoto,lastPhotoFilename, destPhoto, destOrig)  
  # Need a symlink to Pashua in this folder too, include and require moved to top

  $:.push(File.dirname($0))

# The following must be flush left
config = <<end_of_string
# Set transparency: 0 is transparent, 1 is opaque
*.transparency=0.95

# Set window title
*.title = 2. SD card photo downloading options

# Introductory text 
txt.type = text
txt.default = Setting up the downloading and/or copying from SD card. 

# Photo folder select
srcSelect.type = openbrowser
srcSelect.label = Select the folder containing the photos (default is latest card, but may not be up to date):
srcSelect.width = 550
# presumably can use a variable
srcSelect.default = #{srcPhoto}

# Putting in the last photo downloaded from the card and imported to Aperture
# Not sure about default
lastPhoto.type = textfield
lastPhoto.label = Last photo imported to Aperture (from Special Instructions filed):
lastPhoto.width=120
lastPhoto.default = #{lastPhotoFilename}

# Photo folder destination
destPhotoP.type = openbrowser
destPhotoP.label = Select the destination folder for the relabled and GPS coordinated photos:
destPhotoP.width=700
destPhotoP.default = #{destPhoto}

# Move originals to another folder destination
destOrig.type = openbrowser
destOrig.label = Select the destination folder a copy of the original photo files. Only applies to first two options:
destOrig.width=700
destOrig.default = #{destOrig}

# Geolocation for files being renamed. Ignore for now, this is not being used. Only default is an option.
# geoLoc.type = checkbox
# geoLoc.label = Do_ you want to add geo location?
# geoLoc.default = 1


# Add a cancel button with default label
cb.type = cancelbutton

end_of_string

  # Set the images' paths relative to this file's path / 
  # skip images if they can not be found in this file's path
  icon  = File.dirname($0) << "/.icon.png";
  bgimg = File.dirname($0) << "/.demo.png";

# Causing error and think I can live without the icon
#   if File::exist?(icon)    # Display Pashua's icon # exist or exists causing an error
      # Config << "img.type = image # uninitialized constant Config (NameError)
      # img.x = 530
      # img.y = 255
      # img.path = #{icon}
      # "
#   end
# 
#   if File::exist?(bgimg)       # Display Pashua's icon
#       Config << "bg.type = image
#       bg.x = 30
#       bg.y = 2
#       bg.path = #{bgimg}
#       "
#   end

 # pashuaReturn = pashua_run config
  res = pashua_run config
  return  res
  
end # pPashua
