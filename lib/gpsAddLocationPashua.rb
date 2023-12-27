#  Created by Greg Scarich on 2007-07-30.  
# require 'Pashua' # for GUI
require File.expand_path(File.join(File.dirname(__FILE__), 'Pashua'))

include Pashua

# This code is based on that contributed by Mike Hall to Pashua. It uses a module
# Pashua.rb, which is expected to be located either in this script's
# parent directory or in some standard Ruby search path. Please note
# the comments at the top of Pashua.rb.
# http://www.bluem.net/downloads/pashua_en/


def addLocationGUI(srcPhoto)
  # Need a symlink to Pashua in this folder too, include and require moved to top

  $:.push(File.dirname($0))

config = <<end_of_string
# Set transparency: 0 is transparent, 1 is opaque
*.transparency=0.95

# Set window title. "2" since the second window that appears
*.title = 2. Add location information based on fileEXIF only

# Introductory text
txt.type = text
txt.width = 500
txt.default = Select the location of the files to which location information[return] based on GPS coordinates in file EXIF are to be added[return] without moving the files

# Photo folder select
# FIX put in just mounted card when get app to detect mounted cards
srcSelect.type = openbrowser
srcSelect.label = Select the folder containing the photos:
srcSelect.width=550
# presumably can use a variable
srcSelect.default = #{srcPhoto}


# Add a cancel button with default label
cb.type = cancelbutton

end_of_string

 # Set the images' paths relative to this file's path / 
  # skip images if they can not be found in this file's path
  icon  = File.dirname($0) << "/.icon.png";
 bgimg = File.dirname($0) << "/.demo.png";

  if File::exist(icon)    # Display Pashua's icon
      Config << "img.type = image
      img.x = 530
      img.y = 255
      img.path = #{icon}
      "
  end

  if File::exist(bgimg)       # Display Pashua's icon
      Config << "bg.type = image
      bg.x = 30
      bg.y = 2
      bg.path = #{bgimg}
      "
  end

 # pashuaReturn = pashua_run config
  res = pashua_run config
  return  res
  
end # …GUI
