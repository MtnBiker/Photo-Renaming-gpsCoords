### Photo file renaming and GPS coords

A personal script to move photo files (JPG and Raw) from SD card onto Mac, rename the files with the date and time, and to add GPS data based on a GPS track.

Renaming of the files is to the local time and date where the photo was taken. That's the way most of us think about time for a photo. And iPhones use local time, so if you photos from both a "regular" camera and an iPhone and they are sorted by time…

Setup to work with cameras I use or have used. Canon, Panasonic, OMDS

## Usage

/currentData folder no longer used, since now stored on the SD card because I use more than one camera. But am storing a list of photos processed which at present isn't being used.

The GPS info adding is tricky. All GPS devices (AFAIK) use UTM. Most cameras can be set to any time (zone). I used to just set my camera to UTM, but then one of the more recent one allowed viewing the photos or downloading to an iPhone; but doing so set the time to local time.

## Dependencies

mini_exiftools, a Ruby script, to connect with the Perl script ExifTool by Phil Harvey, http://www.sno.phy.queensu.ca/~phil/exiftool/, but has a Windows executable and a Mac OS X package installer available. This is a fantastic, well-maintained package to manipulate photo file EXIF data.

Requires the app Pashua for some of the GUI. However the script is initiated from the command line (or equivalent. I run from TextMate).

### Notes

I'm very much an neophyte Ruby script writer, so at best use this as a guideline. Use at your own risk. I pretty much learned Ruby to write this script. I started this six years ago and am still a rank amateur.

Many of the files aren't being used, but haven't been cleaned out.

2021.01.19 Upgrading to 2021 and seems to run OK. TM_RUBY on iMac is 2.7.1, but now at 3.0.0 on MBP. Pushed to github. Should pull to MBP. Did and then added stashed from MBP to this version.
Was behind on merging. branch 4-2021-working can be abandoned. moveToMylio had gotten left behind
Pushed to master and GitHub so MBP can pull

Used to add location information from geonames and other sources, but too many differences between countries and limits on use and changes that I gave up. Mylio which I'm currently using for my photos add that information based on coordinates, so that's all I need for now. And I usually just need to know where it is on a map, not the geographic descriptions. Maybe implement with exiftool geotag

https://stackoverflow.com/questions/41656336/calling-perl-script-from-ruby-with-ruby-varibles. Same syntax for exiftool
