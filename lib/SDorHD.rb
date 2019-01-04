# Created by Greg Scarich on 2007-07-30.  
# require 'Pashua' # for GUI
require File.expand_path(File.join(File.dirname(__FILE__), 'Pashua'))
include Pashua

# This code is based on that contributed by Mike Hall to Pashua. It uses a module
# Pashua.rb, which is expected to be located either in this script's
# parent directory or in some standard Ruby search path. Please note
# the comments at the top of Pashua.rb.
# http://www.bluem.net/downloads/pashua_en/

# This file is called first. If GPS info is to be added gpsYesPashua is then called from the main script

def whichLoc()  
  # Need a symlink to Pashua in this folder too, include and require moved to top

  $:.push(File.dirname($0))

config = <<end_of_string
# Set transparency: 0 is transparent, 1 is opaque
*.transparency=0.95

# Set window title
*.title = 1. SD card or photos on hard drive

# Introductory text
txt.type = text
txt.default = Deciding whether to copy photos from SD card or use the files already copied to the a folder on the computer. In the next window you'll select the exact location of the photos.

# Moving photos. I think the first letter is used later to select the option. So first letter must be unit
whichDrive.type = radiobutton
whichDrive.label = Do you want photos on an SD card or already copied to the hard drive?
whichDrive.width = 310
whichDrive.option = SD card to be selected in the next window
whichDrive.option = Already downloaded to a folder on a hard drive to be selected in the next window
whichDrive.default = SD card to be selected in the next window

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
