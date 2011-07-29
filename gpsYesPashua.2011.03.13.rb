#  Created by Greg Scarich on 2007-07-30.  
require 'Pashua' # for GUI
include Pashua

# This code is based on that contributed by Mike Hall to Pashua. It uses a module
# Pashua.rb, which is expected to be located either in this script's
# parent directory or in some standard Ruby search path. Please note
# the comments at the top of Pashua.rb.
# http://www.bluem.net/downloads/pashua_en/


def geoGUI(srcPhoto,destPhoto,gpsPhotoLoc,srcGPX,tzoLoc,tzoGPSr,timeOffset,maxTimeDiff,maxDistance,kmzFile)  
          
  # Need a symlink to Pashua in this folder too, include and require moved to top

  $:.push(File.dirname($0))

config = <<end_of_string
# Set transparency: 0 is transparent, 1 is opaque
*.transparency=0.95

# Set window title
*.title = 2. Geo locating options

# Introductory text
txt.type = text
txt.default = Setting up for geocoding of photos.
txt.height = 276
txt.width = 310
txt.x = 270
txt.y = 160

# Photo folder select
# FIX put in just mounted card when get app to detect mounted cards
srcSelect.type = openbrowser
srcSelect.label = Select the folder containing the photos (reconfirming that selected previously):
srcSelect.width=550
# presumably can use a variable
srcSelect.default = #{srcPhoto}


# Time Zone Camera
tzcP.type = textfield
tzcP.label = Time_ Zone Location 
tzcP.default = #{tzoLoc}
tzcP.width = 35

# Camera error
toP.type = textfield
toP.label = Diff. between camera and GPSr. Positive-camera behind. Negative-camera ahead. Seconds
toP.default = #{timeOffset}
toP.width = 55

# Max Time_ Difference
maxTimeDiffP.type = textfield
maxTimeDiffP.label = Max Time_ Difference between GPSr and Camera. Seconds
maxTimeDiffP.default = #{maxTimeDiff}
maxTimeDiffP.width = 45

# Max Distance
maxDistanceP.type = textfield
maxDistanceP.label = Max Distance between GPSr points. meters
maxDistanceP.default = #{maxDistance}
maxDistanceP.width = 45

# KMZ file_
# kmzYN.type = checkbox
# kmzYN.label = Do_ you want to create a KMZ file_ 
# kmzYN.default = 1

# gpx file_ locations
gpxFolder.type = openbrowser
gpxFolder.label = Select the folder containing relevant .gpx files
gpxFolder.width=700
gpxFolder.tooltip = These can either be on your computer or Garmin miniSD card.
gpxFolder.default = #{srcGPX}



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
