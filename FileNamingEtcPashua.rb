#  Created by Greg Scarich on 2007-07-30.  
require 'Pashua' # for GUI
include Pashua

# This code is based on that contributed by Mike Hall to Pashua. It uses a module
# Pashua.rb, which is expected to be located either in this script's
# parent directory or in some standard Ruby search path. Please note
# the comments at the top of Pashua.rb.
# http://www.bluem.net/downloads/pashua_en/

# This file is called first. If GPS info is to be added gpsYesPashua is then called from the main script


def pGUI(srcPhoto,destPhoto,destMovie,photoHandling,movieHandling,addGPS2photos,tzoLoc,tzoF,geoOnlyPref)  
  # Need a symlink to Pashua in this folder too, include and require moved to top

  $:.push(File.dirname($0))

config = <<end_of_string
# Set transparency: 0 is transparent, 1 is opaque
*.transparency=0.95

# Set window title
*.title = 1. Photo downloading, naming options, ...

# Introductory text
txt.type = text
txt.default = Setting up the downloading, renaming, and geocoding of photos. Also create a jpg of each movie for adding to photos (for Aperture).
txt.height = 276
txt.width = 310
txt.x = 270
txt.y = 160

# Photo folder select
# FIX put in just mounted card when get app to detect mounted cards
srcSelect.type = openbrowser
srcSelect.label = Select the folder containing the photos:
srcSelect.width=550
# presumably can use a variable
srcSelect.default = #{srcPhoto}

# Photo folder destination
destPhotoP.type = openbrowser
destPhotoP.label = Select the destination folder for the photos:
destPhotoP.width=700
destPhotoP.default = #{destPhoto}

# Moving photos
photoHandle.type = radiobutton
photoHandle.label = What do_ you want to do_ with the annotated photos?
photoHandle.width = 310
photoHandle.option = Copy to New Destination (above)
photoHandle.option = Move to New Destination (above)
photoHandle.option = Rename in place
photoHandle.default = Copy to New Destination (above)

# Movie folder destination
destMovieP.type = openbrowser
destMovieP.label = Select the destination folder for the movies:
destMovieP.width=700
destMovieP.default = #{destMovie}

# Moving movies
movieHandleP.type = radiobutton
movieHandleP.label = What do_ you want to do_ with the annotated movies?
movieHandleP.width = 310
movieHandleP.option = Copy to New Destination (above)
movieHandleP.option = Move to New Destination (above)
movieHandleP.option = Rename in place
movieHandleP.default = Copy to New Destination (above)

# Time Zone Photo Location
tzcP.type = textfield
tzcP.label = MEANINGLESS NOW. Time_ Zone Location (Local Time Zone used for file naming)
tzcP.default = #{tzoLoc}
tzcP.width = 35

# Time Zone Camera/Photo files
tzoF.type = checkbox
tzoF.label = Leave checked if Camera Setting/Photo files are UTC. UNCHECK if Camera Setting/Photo File is the same as the location above
tzoF.default = 1

# Geolocation for files being renamed
geoLoc.type = checkbox
geoLoc.label = Do_ you want to add geo location? The information will be collected in the next dialog box.
geoLoc.default = 1

# Geolocation ONLY, no renaming
geoOnly.type = checkbox
geoOnly.label = Do_ you ONLY want to add geo location? The information will be collected in the next dialog box. (No file renaming)
geoOnly.default = 0


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
