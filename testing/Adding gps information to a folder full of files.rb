#!/usr/bin/env ruby

# probably don't need any of these for this script
# require 'rubygems' # # Needed by rbosa, mini_exiftool, and maybe by appscript. Not needed if correct path set somewhere.
# require 'mini_exiftool' # Requires Ruby ≥1.9. A wrapper for the Perl ExifTool
# require 'fileutils'
# include FileUtils
# require 'find'
# require 'yaml'
# require "time"

geoInfoMethod = "wikipedia" # for gpsPhoto to select georeferencing source. wikipedia—most general and osm—maybe better for cities
gpsPhotoLoc = "/Users/gscar/Documents/Ruby/Photo handling/lib/gpsPhoto.pl" # Perl script that puts gps locations into the photos. SEEMS TO WORK WITHOUT ./lib ????
downloadsFolders = "/Volumes/Knobby Aperture II/_Download folder/"
destPhoto = downloadsFolders + "Latest Download/" #  These are relabeled and GPSed files.


gpsdir = "\"/Users/gscar/Dropbox/   GPX daily logs/2013 Download/\"" 

# --dir directory    Image directory. Multiple are allowed. This is destPhoto after getting them in that folder labeled but not gps coordinated which will happen if I run the script now, i.e., without gps coords being added

perlOutput = `perl \"#{gpsPhotoLoc}\"   --dir \"#{destPhoto}\" --gpsdir #{gpsdir}  --geoinfo #{geoInfoMethod} --timeoffset 0  --city auto --state guess --country guess  2>&1`


puts "perlOutput: \n#{perlOutput}"