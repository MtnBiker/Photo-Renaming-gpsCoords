puts "RUBY_DESCRIPTION: #{RUBY_DESCRIPTION}\n\n" 

rubyVersionFile = File.dirname(__FILE__) + "/" + ".ruby-version"
if File.exist?rubyVersionFile
  file = File.new(rubyVersionFile, "r")
  while (line = file.gets)
      puts "rbenv local (this folder): #{line}\n"
  end
  file.close
  puts "path to this file: #{File.dirname(__FILE__)}"
else
  puts "#{RUBY_DESCRIPTION}, global rbenv since no .ruby-version file"
end

puts "\nNote that as of 2013.06.10, the photo naming script does not work with ruby 1.9.3"
# this file not part of Photo naming…


