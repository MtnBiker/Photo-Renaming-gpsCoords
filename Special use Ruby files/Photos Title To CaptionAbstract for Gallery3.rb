# EXIF Title to EXIF Caption-Abstract. 
# Because Gallery3 shows Caption-Abstract as the "Caption". Photos has Title which we want to see as Caption

require 'cgi'
require 'mini_exiftool' # a wrapper for the Perl ExifTool
require 'fileutils'
include FileUtils

src  = "/Users/gscar/Documents/◊ Pre-trash/galleryTest/"
i = 0
i_commented = 0
Dir.foreach(src) do |item| 
  next if item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon ' 
  i += 1
  fn = src + item
  if File.file?(fn) # 
    puts "Tick …" # because slow
    fileEXIF = MiniExiftool.new(fn)
    exifTitle = fileEXIF.title
    puts "#{i_commented}. exifTitle: #{exifTitle}"
    fileEXIF.CaptionAbstract = exifTitle
    fileEXIF.save
    i_commented += 1
  end
end
       
puts "#{i_commented} of #{i} files had Title copied to EXIF ImageDescription (Gallery3 Caption)"   
   # NOT TESTED WITH FileUtils.move(src,
   # Nice to move annotated files too, but need to refactor to handle rescue