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
   renaming needs stacking information which should benefit from Array.photos. really a hash. Should I name it Hash.photos? FIXME

2. Rename in place in renamePhotoFiles
   Do in reverse so know if a stacked image
   ori to ORF (noted in preservedFileName if need to find it
   1. If "Focused-stacked" (stackedImage), get count and confirm next x are Focus Bracketing and set aside and mark as brackets
   `2024.11.13-09.02.57(FS).gs.O.orf` # is this a good convention for Focus-Stacked? ~Line 212
   Bracketed shots @driveMode="Focus Bracketing, Shot 15; Electronic shutter",
   √ Maybe if `Focus Bracketing` and Shot no >1 and <100 rename as bracket and set aside. In line or as a method?. Set a flag that FS has happened stackedImageBoolean
   Focus-bracketing with no stack
   2. Later realized that using case was the best way to handle the various situations (cases! obviously)
   √ 102 files in virgin…, now working
  dupCount to sameSec, maybe should be seqNo or similar
   fileBaseName = "#{fileDateStr}.ProCap#{shot_no}.#{userCamCode}" put shot_no after to separate from date. See if that's better
   
   sameSecondTrue() probably not doing much, most of it is not being used
  √ -2ss sequency for same second would be better off as a, b, c etc
   
   √ are being made different basenames 2024.12.07-14.10.59 OC076017 Fixed
   
3. √ add gps coordinates. Can do this before or after renaming, but before moving

HiResTripod contributing orf (OB035290) not being so identified: should maybe be bkt and would be set aside. 2024.10.18-10.53.10.SS.gs.O.orf or 2024.10.18-10.53.10b.gs.O.orf Have to find three in a row with the first two being HiResTripod and the third being stackedImage No, but it's an ORI, maybe leave it as such so can pick it out.

or 2024.11.03-08.30.53-ss2.gs.O.orf or 
OM EXIF for FileType and FileTypeExt for an .ori is ORF, so should use macOS to get extension
OB035290.ORI.2024.11.03-08.30.53.SS.gs.O.ori but gets SS label. It is a single shot so not wrong FIXME?

√ 2024.11.11-10.08.29.SS.gs.O.jpg is a single shot, but not special so .ss should go away it's this way without numbers_to_letters. DONE

Added copy_with_mac_renaming(fn, fnp) from ChatGPT to prevent writing over files. Not fully tested. Works with no duplicates. But later created errors 

4 Then can sort by where to go: jpg if raw exists, unneeded files for stack, unneeded files from hi res

## ToDo
Prevent redownloading from the two cards
dateTimeOriginal replace with createDate. .mov doesn't have dateTimeOriginal
Look at EXIF filename vs Ruby basename for consistency, but be aware of my `fileBaseName`
sameSecondTrue() probably not doing much, most of it is not being used
Add to instructions or somewhere if a bracketed image has a stack
timeNow etc reports are a mess

## ToDone
-2ss sequencing for same second would be better with a, b, c etc

### Changes
photosRenamedTo left in as it might be useful for dubugging. But I wasn't using it and maybe it should go into photos.array. Action not implemented, ie, file not written to.

GUI
writeCaption = true # Decide this is GUI later

fileDateTimeOriginal review what this is for FIXME
DateTimeUTC and DateTimeOriginal and OffsetTime to check that camera was set correctly. These are what the camera thinks is right. Maybe check against the time zones.yml, but ignore for now

#### test images. See file: OM EXIF for different shooting modes.numbers
virginOMcopy folder 102 photos
OA184727–OA184736 10 photos  "Continuous Shooting Shot xx; Electronic shutter",
OA184737 "Single Shot; Electronic shutter",
OA184738–OA184742 5 photos "Continuous Shooting, Shot x; Electronic shutter",
OA184805–OA184819 Focus stacking and result.
OB035290–OB035291 Two sets of HiRes (3 images each)  The ori image does not specify it's a part of the Hi-Res
OB035300 and OB045343 Two single shot jpg
OB045344 another HiRes (3 images),   #### Tripod Hi-Res 3 images. ori image does not specify it's a part of the Hi-Res
OB115647 jpg preceding a focus stack
OB115648–OB115662 Focus bracketing and result (16 total)
OB115663 following jpg
OB115666.MOV 
OB115667.JPG
OC076017 orf jpg pair
OC076017–OC146048 Bracketed (no stack) with none-Pro lens
OC146065–OC146079 Focus stacked with jpg/orf pairs with final 
OC146080 Final jpg stacked

Note EXIF
FileName : OB035290.ORF # just the name and extension

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
