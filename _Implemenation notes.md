#### Implementation notes

GPS coords not being written to OM-1 files—maybe they are
Is this error relevant?: 618. Finding all gps points from all the gpx files using gpsPhoto.pl. This may take a while.

Error writing /Volumes/Daguerre/\_Download folder/Latest Processed photos-Import to Mylio/2024.03.01-17.51.30.gs.O_OzXA7s.jpg,
error: [minor] MakerNotes tag 0x2010 IFD format not handled. 623. perlOutput:
Processing directory "/Users/gscar/Documents/GPS-Maps-docs/ GPX daily logs/2024 GPX logs/". 2 gps files.
Found 2 total gps file names.
Parsing GPX file "/Users/gscar/Documents/GPS-Maps-docs/ GPX daily logs/2024 GPX logs/2024.02.29-03.02.gpx": 2281 points.
Parsing GPX file "/Users/gscar/Documents/GPS-Maps-docs/ GPX daily logs/2024 GPX logs/2024.03.03.gpx": 1203 points.
Processed 3484 coordinates.
Found only 3481 disjunct time stamps.
Processing directory "/Volumes/Daguerre/\_Download folder/Latest Processed photos-Import to Mylio//". 40 images.
Found 40 total image file names.
/Volumes/Daguerre/\_Download folder/Latest Processed photos-Import to Mylio/2024.03.01-17.51.30.gs.O.jpg, 2024-03-01T17:51:30Z, timediff=359 to 17:57:37
Lat 33.812168, Lon -118.383879 - Bearing: unknown - Altitude: 50m

After tagging photos using Oi app

Error writing /Volumes/Daguerre/\_Download folder/Latest Processed photos-Import to Mylio/2024.03.01-17.51.30.gs.O_hxE4D6.jpg,
error: [minor] MakerNotes tag 0x2010 IFD format not handled. 629. perlOutput:
Processing directory "/Users/gscar/Documents/GPS-Maps-docs/ GPX daily logs/2024 GPX logs/". 2 gps files.
Found 2 total gps file names.
Parsing GPX file "/Users/gscar/Documents/GPS-Maps-docs/ GPX daily logs/2024 GPX logs/2024.02.29-03.02.gpx": 2281 points.
Parsing GPX file "/Users/gscar/Documents/GPS-Maps-docs/ GPX daily logs/2024 GPX logs/2024.03.03.gpx": 1203 points.
Processed 3484 coordinates.
Found only 3481 disjunct time stamps.
Processing directory "/Volumes/Daguerre/\_Download folder/Latest Processed photos-Import to Mylio//". 41 images.
Found 41 total image file names.
/Volumes/Daguerre/\_Download folder/Latest Processed photos-Import to Mylio/2024.03.01-17.51.30.gs.O.jpg is already geotagged.
Skip track correlation.
, get geotag from meta info.
Lat 33.8036305555556, Lon -118.383177777778 - Bearing: unknown - Altitude: 112m

====
Coords are different
Lat 33.812168, Lon -118.383879 - Bearing: unknown - Altitude: 50m -- normal method
Lat 33.8036305555556, Lon -118.383177777778 - Bearing: unknown - Altitude: 112m -- Oi app
33.803635, -118.383186

2024.03.15 Working on OM-1 integration. Larger number of sequence shots possible. But in some cases at least there is a shot no. Did some maybe messed up fixes. Use dupCount for now. No should be able to use seq no

- how handle two cards in OM-1?
