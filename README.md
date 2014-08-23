### Photo file renaming and GPS coords

A personal script to move photo files (JPG and RAW) from SD card onto Mac, rename the files with the date and time, and to add GPS data based on a GPS track.

Setup to work with cameras I use or have used.

## Usage

Camera is kept on UTC, i.e., the same time system as the GPS.

## Dependencies
yaml
mini_exiftools, a Ruby script, to connect with the Perl script ExifTool by Phil Harvey, http://www.sno.phy.queensu.ca/~phil/exiftool/, but has a Windows executable and a Mac OS X package installer available. This is a fantastic well maintained package to manipulate photo file EXIF data.

### Notes

I'm very much a neophyte Ruby script writer, so at best use this as a guideline. Use at your own risk. I pretty much learned Ruby to write this script. 