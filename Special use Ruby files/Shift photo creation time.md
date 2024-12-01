Command line

##### exiftool -geotag -geosync=-14:00:00 "/Users/gscar/Documents/GPS-Maps-docs/ GPX daily logs/2024 GPX logs/Untitled.gpx" "/Volumes/Mylio 4TB/Mylio_87103a/Mylio Main Library Folder/2020s/2024/Mongolia 2024/30Sept/" ## this worked

But supposed to look like
exiftool -geosync=-14:00:00 -geotag ="/…/Untitled.gpx" "/Volumes/Mylio 4TB/Mylio_87103a/Mylio Main Library Folder/2020s/2024/Mongolia 2024/30Sept/"

exiftool -geotag -geosync=-14:00:00 gpxFile photoOrFolderWithPhotos

exiftool -geotag=track.log /Users/Phil/Pictures or it figures it out

For example, "-geosync=-1:20" specifies that synchronization with GPS time is achieved by subtracting 1 minute and 20 seconds from the Geotime value. See the Time Synchronization Tip below for more details.

#### This time difference may be of the form "SS", "MM:SS", "HH:MM:SS" or "DD HH:MM:SS" (where SS=seconds, MM=minutes, HH=hours and DD=days), and a leading "+" or "-" may be added for positive or negative differences (positive if the GPS time was ahead of the camera clock)

https://exiftool.org/geotag.html
