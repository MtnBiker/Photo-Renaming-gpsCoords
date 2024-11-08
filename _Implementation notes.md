#### Implementation notes

Earlier version of this is at /Users/gscar/Documents/Ruby/Photo handling-Lumix/
Too much cruft and very slow now. So will get rid of known cruft and anything not related to OM
"Special use Ruby files" files will be deleted from this original project so not duped in new version

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

mini_exiftool did not handle getting DriveMode or Special Mode (author responded and is trying to fix it), but in the interim: https://stackoverflow.com/questions/78257612/how-to-introduce-a-filename-into-shell-script-in-ruby-script#78257612 provided answers and work around.

Regular photo:
Drive Mode : Single Shot; Electronic shutter
Special Mode : Normal, Sequence: 0, Panorama: (none)

29. Focus bracketing:
    Drive Mode : Focus Bracketing, Shot 6; Electronic shutter
    Special Mode : Fast, Sequence: 6, Panorama: (none)

30. High speed sequential, SH1:
    Drive Mode : Continuous Shooting, Shot 80; Electronic shutter
    Special Mode : Fast, Sequence: 80, Panorama: (none)

For at least focus bracketing and SH1, DriveMode may be more useful info because it has a shot number (and will try to get the -1 in since my existing script doesn't do that, only the subsequent ones) and the added but probably unneeded Shooting mode
Special Mode always has Sequence which could be used for sorting, but still wouldn't include photos just taken in the same second (see line above for fix)
--
** Problem is multiple shots in same second, particularly since OM doesn't report subsecs. And can take up to 120 fps, so my old scheme of using letters fell short **
At the moment I see three scenarios: 1) Normal repeated shots within same second (unlikely to be more than a few), 2) ProCapture (SH1, SH2, etc. ~ 8 variations), 3) Focus Stacking and Bracketing.
Could just add a number for each shot. That is fine for scenario 1, but for 2 and 3 might be nice to have a sequential number even or multiple seconds. Or is this unnecessarily confusing? Maybe, but I'll pursue this in this format `2024.03.30-16.48.45-5.gs.O.orf`. And using current method, the `-0` won't be shown. One complication at the moment is having to keep .jpg in Mylio since macOS doesn't handle OM-1 II files yet.
Could add a notation based on Drive Mode: brk or similar for Bracketing and `pc` or `sh` for ProCapture modes. But leave this for later. What's SH stand for? `pc` stands for too many other things

So: look for photos in same second (could miss if sequential but first is in the preceding second) and look for shot_no in Drive Mode of Special Mode. Preferring Drive Mode since also has what shooting mode. Done I think except first photo in a series isn't labeled as such

Have added something to get shot 1, but untested as of yet. Works. mini_exiftool now working

But GPS does not appear to be working. gpsPhoto.pl seems to have stopped working. Maybe `exiftool -geotag=<trackfile> <image_dir>`
Use wildcards to load multiple track files (the quotes are necessary for most operating systems to prevent filename expansion):

exiftool -geotag "TRACKDIR/\*.log" IMAGEDIR
exiftool -geotag "logs/\*.log" dir https://exiftool.org/geotag.html#Examples
Use wildcards to load multiple track files (the quotes are necessary for most operating systems to prevent filename expansion):

Test. -overwrite_original goes at end. Following for command line
exiftool -geotag "/Users/gscar/Documents/GPS-Maps-docs/ GPX daily logs/2024 GPX logs/\*.gpx" "/Volumes/Daguerre/\_Download folder/ Drag Photos HERE/" -overwrite_original

For script, double quotes for all, not backtick
exiftoolGps = system("exiftool", "-geotag", "#{gpxLogs}", "#{photoFolder}", "-overwrite_original")

exiftool -geotag works. Confirm doesn't overwrite existing geotags (-if "not $gpslatitude"), would matter if had already done in OM or for iPhone photos. Asked exiftool forum

Look at https://exiftool.org/geolocation.html when get to v

7 hours to process 2920 images.

Need to create a copy for OM only

Separating OM and Lumix since different fields written to. Some of the logic may be a mess. Not a mess, but may need rethinking. See notes in Notes

Getting confused when trying to get photos via USB-C cable reading direct from camera

Exception: Operation not permitted @ rb_sysopen when try to open /Volumes/OM SYSTEM/lastPhotoRead.txt from Nova, works in TextMate
sudo chmod a+rw "/Volumes/OM SYSTEM/lastPhotoRead.txt" # suggested as a fix and it worked. Happened again and had to run from iTerm. Took a computer reboot also.

May be working in Nova for OM. Need to confirm Lumix

If manually type last photo doesn't work. 183 globStart = lastPhotoFilename.slice(0)+"\*" # Selected first letter of last file name

2024.10.12 All except one of the files in in /lib were blank. Copied from an old backup since little change IIRC. Ultimately a problem with Apple iCloud. I'm pushing to have Git and iCloud on same files

For focus stacked images, I don't want to put the images that contribute be put in Mylio. OK to save to archive. Maybe a note about that. Added some fields. Write to caption since can only put so much info in the name and Special Instructions is easily missed. Works but thought I saw a mess up.

Change .ori to .ori.orf so Mac can open. And fileEXIF.CameraType2 = "OM-1" on .orf
