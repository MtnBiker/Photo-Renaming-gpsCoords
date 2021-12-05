#!/usr/bin/env ruby
require 'cgi'
require 'mini_exiftool' # a wrapper for the Perl ExifTool
require 'fileutils'
include FileUtils

src  = "/Users/gscar/Pictures/2021 SD card recover/LexarRecoveredFolder/2021-11-30 08-05-08/Picture/"
i = 0
i_commented = 0
# afterDate = Time.now # - 6.days
afterDate = Date.parse("2021-11-20 17:03:54 -0800")
puts "afterDate: #{afterDate}"
Dir.foreach(src) do |item| 
  next if item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon ' 
  i += 1
  fn = src + item
  if File.file?(fn) # 
    fileEXIF = MiniExiftool.new(fn)
    createDate = fileEXIF.CreateDate
    if createDate > afterDate
       puts "#{i_commented}. createDate: #{createDate} for #{item}"

    end
    fileEXIF.save
    i_commented += 1
  end
end
       
    # puts "#{i_commented} of #{i} files had Title copied to EXIF ImageDescription (Gallery3 Caption)"
       # NOT TESTED WITH FileUtils.move(src,
       # Nice to move annotated files too, but need to refactor to handle rescue