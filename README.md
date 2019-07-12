### Photo file renaming and GPS coords

A personal script to move photo files (JPG and RAW) from SD card onto Mac, rename the files with the date and time, and to add GPS data based on a GPS track.

Setup to work with cameras I use or have used.

## Usage

/currentData folder no longer used, since now stored on the SD card because I use more than one camera. But am storing a list of photos processed which at present isn't being used

## Dependencies

mini_exiftools, a Ruby script, to connect with the Perl script ExifTool by Phil Harvey, http://www.sno.phy.queensu.ca/~phil/exiftool/, but has a Windows executable and a Mac OS X package installer available. This is a fantastic, well-maintained package to manipulate photo file EXIF data.

Requires the app Pashua for some of the GUI. However the script is initiated from the command line (or equivalent. I run from TextMate).

geonames.rb. Not sure whose version, but I have a local copy. Can't remember if gem didn't work or what.

### Notes

I'm very much an neophyte Ruby script writer, so at best use this as a guideline. Use at your own risk. I pretty much learned Ruby to write this script. I started this six years ago and am still a rank amateur. 

Many of the files aren't being used, but haven't been cleaned out.