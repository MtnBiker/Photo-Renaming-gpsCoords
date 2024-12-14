## Outline of how PhotoNeme-GPScoords-macOSphotos was put together

Nov 2024
Test files
HiRes (should be three) Mouse + orf. jpg, ori
Focus Stacking in camera-so files I don't want to put into Mylio. Mouse 15 images + Focus-stacked \_STK
Focus Bracketing - not stacked in camera. Process in another app. 14 images xxbkt

905 Check if processing folders are empty
985 Pashua: SD or folder
1018 GPS coordinates only
1059 last file read from SD card
1151 Copy from SD card, archive a copy, copy to processing folder (mylioStaging)
1205 renamePhotoFiles() returns tzoLoc, camModel
Dir.each
611ff read shooting mode parameters and write to Caption/description
bracketing: if driveMode == "Focus Bracketing"
shot no. from driveMode `Continuous Shooting, Shot 12; Electronic shutter`
662 append .orf to .ori files so Apple apps can handle them as orf which they are. .ori is just the first shot of a composite file such as a hi-res
721 stackedImage: Focus-stacked or Tripod or Hand-held high resolution
737 filename for bracketed or stacked
739 filename for oneBack
740 filename for others
752 fileAnnotate()
instructions: shooting mode information (similar to what writing to Caption/description because seen in EXIF in Mylio, but harder to find)
\*\*\* should these two be the same or do they serve different purposes. If the same should be in a module or just reused as in the loop

- - Yes the same since Caption might be erased or maybe not written if too annoying
    TimeZoneOffset, PreservedFileName
    returns tzoLoc, camModel of the last photo
    767 File.rename(fn,fnp) original and new name
    770 file_prepend last photo copied to
    798 If an in camera stacked file, move the shots comprising that photo to unneededBracketed
    1245 and 1253—this is screwed up, since not in a ifelse calls 573 renamePhotoFiles() # Rename the jpgs and then move to Latest Download. Second call to rename, first is for raw?
    1193 Move jpgs to mylioStaging
    1202 exiftoolAddCoordinates( to all photos in mylioStaging (note if move bracket photos, will have to repeat for them ##\*#
    Need to figure out where to park focus bracketing photos and inputs to Focus stacked photos

FS: In camera focus stacked

### PhotoProcessing-OM which includes creating a class and refactoring

For OM-1 only
Folders to be changed marked for production with DEV
DEV will have manual entering of where files are and will not save to Mylio
GUI for keying into GUI options etc

12/3/2024 Basic class established 0. Copy from card to staging and a copy to archive which is probably what I'm doing. If it is then go to 1——this can be done later and will need Glimmer DSL for LibUI

1. Write preservedFileName, etc
   √ probably can do that in the existing read loop
   √ Anything else to write. Probably line 621 establishes imageDescription and
   renaming needs stacking information which should benefit from Array.photos

2. Rename in place
   ori to ORF (noted in preservedFileName if need to find it
3. add gps coordinates. Can do this before or after renaming, but before moving

4 Then can sort by where to go: jpg if raw exists, unneeded files for stack, unneeded files from hi res

### Changes
photosRenamedTo left in as it might be useful for dubugging. But I wasn't using it and maybe it should go into photos.array. Action not implemented, ie, file not written to.

GUI
writeCaption = true # Decide this is GUI later

fileDateTimeOriginal review what this is for FIXME
DateTimeUTC and DateTimeOriginal and OffsetTime to check that camera was set correctly. These are what the camera thinks is right. Maybe check against the time zones.yml, but ignore for now

#### test images
virginOMcopy folder
OA184727–OA184742 Two sets of Continuous shooting (heavy finger on shutter or)
OA184805–OA184819 Focus stacking and result
OB035290–OB035292 Three sets of HiRes (3 images each)
OB035300 and OB045343 Two single shot jpg
OB045344 another HiRes (3 images)
OB115647 jpg preceding a focus stack
OB115648–OB115662 Focus stack and result (16 total)
OB115663 following jpg
OC076017 orf jpg pair


$$
Easier to read this in Notes app. Examples saved
Examples of Hi-Res shots saved. 3 saved with same file basename, but different extension
Stacked Image: `Tripod high resolution`. shotNo: 00. driveMode: Single Shot; Electronic shutter.   preservedFileName: OB035290.JPG
Stacked Image: `Tripod high resolution`. shotNo: 00. driveMode: Single Shot; Electronic shutter. preservedFileName: OB035290.ORF
Stacked Image: `No`. shotNo: 00. driveMode: Single Shot; Electronic shutter.   preservedFileName: OB035290.ORI

Stacked Image: `Hand-held high resolution (11 12)`. shotNo: 00. driveMode: Single Shot; Electronic shutter.  preservedFileName: OB175720.JPG
Stacked Image: `Hand-held high resolution (11 12)`. shotNo: 00. driveMode: Single Shot; Electronic shutter.  fpreservedFileName: OB175720.ORF
Stacked Image: `No`. shotNo: 00. driveMode: Single Shot; Electronic shutter. preservedFileName: OB175720.ORI

If the Hand-held high resolution (11 12).orf exists put the preceding jpg and succeeding .ori aside


Stacking, focus, etc
Stacked Image : No or Focus-stacked. None in O8[2024.08]-OM/.
Does EXIF tell if bracketed images have been successfully stacked?
No. The images comprising a successfully stacked image have the same EXIF as one from a bracketed or unsuccessfully stacking
Both have: Focus Bracketing, Shot xx as part of DriveMode
   # DriveMode       : Focus Bracketing, Shot 8; Electronic shutter
   # DriveMode shows "Focus Bracketing" for the shots comprising the focus STACKED result

Stacked Image: `No`. shotNo: 01. driveMode: Focus Bracketing, Shot 1; Electronic shutter.  f1.  preservedFileName: OB035274.JPG
…02–14
Stacked Image: `No`. shotNo: 15. driveMode: Focus Bracketing, Shot 15; Electronic shutter.  1.  preservedFileName: OB035288.JPG
Stacked Image: `Focus-stacked (15 images)`. shotNo: 00. driveMode: Single Shot; Electronic shutter.  preservedFileName: OB035289.JPG

If Focus-stacked (15 images), set aside 15 preceding items with a shotNo. file basenames are in logical order
$$