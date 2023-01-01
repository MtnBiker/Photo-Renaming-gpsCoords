#  Created by Greg Scarich on 2007-07-30.  
# require 'Pashua' # for GUI
require File.expand_path(File.join(File.dirname(__FILE__), 'Pashua'))

include Pashua

# This code is based on that contributed by Mike Hall to Pashua. It uses a module
# Pashua.rb, which is expected to be located either in this script's
# parent directory or in some standard Ruby search path. Please note
# the comments at the top of Pashua.rb.
# http://www.bluem.net/downloads/pashua_en/

# This file is called first. If GPS info is to be added gpsYesPashua is then called from the main script


def pGUI(srcPhoto,destPhoto,destOrig)  
  # Need a symlink to Pashua in this folder too, include and require moved to top

  $:.push(File.dirname($0))
  destOrig = destOrig + "/" # the plus part is trying to fix what happens when pick the archive folder, but probably isn't right

config = <<end_of_string
# Set transparency: 0 is transparent, 1 is opaque
*.transparency=0.95

# Set window title
*.title = 2. Photo downloading, naming options, ...

# Introductory text
txt.type = text
txt.default = Setting up the relabeling of photos downloaded to the hard drive.

# Photo folder select
# FIX put in just mounted card when get app to detect mounted cards
srcSelect.type = openbrowser
srcSelect.label = Select the folder containing the photos:
srcSelect.width=550
# presumably can use a variable
srcSelect.default = #{srcPhoto}

# Photo folder destination
destPhotoP.type = openbrowser
destPhotoP.label = Select the destination folder for the photos (IGNORED if not moving.):
destPhotoP.width=700
destPhotoP.default = #{destPhoto}

# Move originals to another folder destination
destOrig.type = openbrowser
destOrig.label = Select the destination folder for the original files for the last option below (IGNORED if not moving.):
destOrig.width=700
destOrig.default = #{destOrig}

# Geolocation ONLY, no renaming
# geoOnly.type = checkbox
# geoOnly.label = Do_ you ONLY want to add geo location? The information will be collected in the next dialog box. (No file renaming or relocating.)
# geoOnly.default = 0

# # Moving photos. I think the first letter is used later to select the option. So first letter must be unit
# photoHandle.type = radiobutton
# photoHandle.label = What do_ you want to do_ with the annotated photos? (Doesn't apply for geo location ONLY)
# photoHandle.width = 310
# photoHandle.option = Copy to New Destination (above)
# photoHandle.option = Move to New Destination (above)
# photoHandle.option = Rename in place
# photoHandle.option = I: Annotate a copy of the photo and place in the New Destination (above), and move the original to the last folder above.
# photoHandle.default = I: Annotate a copy of the photo and place in the New Destination (above), and move the original to the last folder above.

# Add a cancel button with default label
cb.type = cancelbutton

end_of_string

 # Set the images' paths relative to this file's path / 
  # skip images if they can not be found in this file's path
  icon  = File.dirname($0) << "/.icon.png";
  bgimg = File.dirname($0) << "/.demo.png";

  if File::exists?(icon)    # Display Pashua's icon
      Config << "img.type = image
      img.x = 530
      img.y = 255
      img.path = #{icon}
      "
  end

  if File::exists?(bgimg)       # Display Pashua's icon
      Config << "bg.type = image
      bg.x = 30
      bg.y = 2
      bg.path = #{bgimg}
      "
  end

 # pashuaReturn = pashua_run config
  res = pashua_run config
  return  res
  
end # pGUI
