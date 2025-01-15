class Photo
   
  @@count = 0 ## not using, but should figure out how to do this, see commented out below
   
  attr_accessor :id, :fn, :fileName, :fileExt, :camModel, :fileType, :stackedImage, :driveMode, :specialMode, :afPointDetails, :subjectTrackingMode, :createDate, :sameSecond, :dateTimeOriginal, :offsetTimeOriginal, :preservedFileName
  # order by need for sorting and dealing with
   
  def initialize(id, fn, fileName, fileExt, camModel, fileType, stackedImage, driveMode, specialMode, afPointDetails, subjectTrackingMode, createDate, sameSecond, dateTimeOriginal, offsetTimeOriginal, preservedFileName)
    
    @id = id
    @fn = fn
    @fileName = fileName # same as preservedFileName, but fileName is not viewable in Mylio
    @camModel = camModel
    @fileExt = fileExt
    @fileType = fileType
    @stackedImage = stackedImage
    @driveMode = driveMode
    @specialMode = specialMode
    @afPointDetails = afPointDetails
    @subjectTrackingMode = subjectTrackingMode
    @createDate = createDate
    @sameSecond = sameSecond
    @dateTimeOriginal = dateTimeOriginal,
    @offsetTimeOriginal = offsetTimeOriginal
    @preservedFileName = preservedFileName
  end
    
    # The counting needs work if I need it, where did I get it from
    # Every time a Photo (or a subclass of Photo) is instantiated,
    # we increment the @@count class variable to keep track of how
    # many photos have been created.
    # self.class.increment_count # Invoke the method.
  
    # def self.increment_count
    # 	@@count += 1
    # end
    # 
end # class Photo
