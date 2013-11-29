# puts "RUBY_DESCRIPTION: #{RUBY_DESCRIPTION}\n\n" 

rubyVersionFile = File.dirname(__FILE__) + "/" + ".ruby-version"
if File.exist?rubyVersionFile
  file = File.new(rubyVersionFile, "r")
  while (line = file.gets)
      puts "rbenv local (this folder): #{line}\n"
  end
  file.close
  puts "path to this file: #{File.dirname(__FILE__)}"
else
  puts "RUBY_DESCRIPTION: #{RUBY_DESCRIPTION}. Global rbenv since no .ruby-version file"
end


