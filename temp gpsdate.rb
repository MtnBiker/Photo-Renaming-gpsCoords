gpxFile = srcGPX + fileDateUTC.strftime("%Y%m%d") + ".gpx"

# creating list of gpx files needed for geo locating maybe a method later
if gpxDate.include?(fileDate.strftime("%Y%m%d")+ ".gpx")
  # file already exists, don't bother
else
   gpxDate << fileDate.strftime("%Y%m%d")+ ".gpx" # looks slightly inefficent, but usually only add a few elements
end


  gpxDateFN =[]
  gpxDate.each {|x| gpxDateFN<<(srcGPX+x)} # still assuming all the needed files exist
  # puts "gpxDateFN:"
  # puts gpxDateFN
  gpxDateFN.each {|x| if !File.exists?(x); puts "#{x} is missing and is needed";gpxFlag=true;end} # noting missing files
  gpxDateFN.delete_if {|x| !File.exists?(x)} # deleting references to gpx files that don't exist
#  puts "gpxDateFN: #{gpxDateFN}"
# need a list of the file names looking like --gpsfile "the/whole/long/filename.gpx" Could modify s.shell_escape to do this, but it works as is
  gpxFiles=[]
  gpxDateFN.each {|x| gpxFiles<<(gpsfile+x+dqs)}  # x is the date


What is needs to look like:
--gpsfile "/Users/gscar/Documents/GPS-Maps-docs/   Garmin gpx daily logs/2011 Download/20110606.gpx" --gpsfile "/Users/gscar/Documents/GPS-Maps-docs/   Garmin gpx daily logs/2011 Download/20110607.gpx" --gpsfile "/Users/gscar/Documents/GPS-Maps-docs/   Garmin gpx daily logs/2011 Download/20110608.gpx"

Currently just this in gpsinfo module, so is the complete filename for one file, but not exactly what gpsphoto needs to see
gpxFile = srcGPX + fileDateUTC.strftime("%Y%m%d") + ".gpx"

=========
New:
#  Initialize
gpsfile = "--gpsfile \""
dqs="\" " # dqs double quote space
gpxFiles=[]

# First, i.e. the day (letting gps photo find if the file exists, see if this works)
gpxFile = srcGPX + fileDateUTC.strftime("%Y%m%d") + ".gpx"
gpxFiles<<(gpsfile+gpxFile+dqs)}
if tzoLoc > 0
  # need previous day
  diffDate = fileDateUTC - day # is this possible?
  puts "diffDate: #{diffDate}"
  gpxFile = srcGPX + diffDate.strftime("%Y%m%d") + ".gpx"
  gpxFiles<<(gpsfile+gpxFile+dqs)}
else
  # need next day
  diffDate = fileDateUTC + day # is this possible?
  puts "diffDate: #{diffDate}"
  gpxFile = srcGPX + diffDate.strftime("%Y%m%d") + ".gpx"
  gpxFiles<<(gpsfile+gpxFile+dqs)}
end
puts "gpxFiles: #{gpxFiles}" 

