#  Created by Greg Scarich on 2007-07-30.  
# require 'Pashua' # for GUI
require File.expand_path(File.join(File.dirname(__FILE__), 'Pashua'))

include Pashua

# This code is based on that contributed by Mike Hall to Pashua. It uses a module
# Pashua.rb, which is expected to be located either in this script's
# parent directory or in some standard Ruby search path. Please note
# the comments at the top of Pashua.rb.
# http://www.bluem.net/downloads/pashua_en/


def gpsCoordsGUI(srcPhoto)
  # Need a symlink to Pashua in this folder too, include and require moved to top

  $:.push(File.dirname($0))

config = <<end_of_string
# Set transparency: 0 is transparent, 1 is opaque
*.transparency=0.95

# Set window title
*.title = 2. Add GPS coordinates only

# Introductory text
txt.type = text
txt.width = 500
txt.default = Select the location of the files to which GPS coordinates are to be added[return]without moving the files

# Photo folder select
# FIX put in just mounted card when get app to detect mounted cards
srcSelect.type = openbrowser
srcSelect.label = Select the folder containing the photos (may have to drag in the folder):
srcSelect.width = 550
srcSelect.default = #{srcPhoto}


# Add a cancel button with default label
cb.type = cancelbutton

end_of_string

  # Set the images' paths relative to this file's path
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
  
end # gpsCoordsGUI
