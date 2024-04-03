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

For at least focus bracketing and SH1, DriveMode may be more useful info
Special Mode always has Sequence which could be used for sorting, but still wouldn't include photos just taken in the same second
--
Problem is multiple shots in same second, particularly since OM doesn't report subsecs. And can take up to 120 fps, so my old scheme of using letters fell short
At the moment I see three scenarios: 1) Normal repeated shots within same second (unlikely to be more than a few), 2) ProCapture (SH1, SH2, etc. ~ 8 variations), 3) Focus Stacking and Bracketing.
Could just add a number for each shot. That is fine for scenario 1, but for 2 and 3 might be nice to have a sequential number even or multiple seconds. Or is this unnecessarily confusing? Maybe, but I'll pursue this in this format `2024.03.30-16.48.45-5.gs.O.orf`. And using current method, the `-0` won't be shown. One complication at the moment is having to keep .jpg in Mylio since macOS doesn't handle OM-1 II files yet.
Could add a notation based on Drive Mode: brk or similar for Bracketing and `pc` or `sh` for ProCapture modes. But leave this for later. What's SH stand for? `pc` stands for too many other things

So: look for photos in same second (could miss if sequential but first is in the preceding second) and look for shot_no in Drive Mode of Special Mode. Preferring Drive Mode since also has what shooting mode.
