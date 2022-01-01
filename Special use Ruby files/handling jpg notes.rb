copyAndMove(srcHD,destPhoto, tempJpg, destOrig, photosArray)
copyAndMove:
srcHD: (should be renamed)
destPhoto: copy to here and rename here later. First round Raw and jpg if no Raw
tempJpg: temporary destination for jpg paired with a Raw
destOrig: for archiving the originals 
photosArray: within copyAndMove each file is added and is returned. I think intended for storing this info for relabeling [arrayIndex, item, fnp, itemPrevExtName]

First round
photosArray = copyAndMove(srcHD, destPhoto, tempJpg, destOrig, photosArray)


For the jpgs (second round)
photosArray = copyAndMove(tempJpg, destPhoto, tempJpg, destOrig, photosArray)

location of file is same as where move jpgs, but need  test to ignore

TODO: sort out copyAndMove and its handling of jpg

renaming not done in copyAndMove(), but photosArray has ?

rename can't handle jpg and Raw for same photo because of how it handles photos in the same second. Should I fix that instead. It's a mess already though
