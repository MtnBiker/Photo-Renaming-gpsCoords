#!/usr/bin/env ruby
# Refactored new version 2013.12.10 and Ruby 2 compatibility

require 'rubygems' # # Needed by rbosa, mini_exiftool, and maybe by appscript. Not needed if correct path set somewhere.
require 'mini_exiftool' # Requires Ruby ≥1.9. A wrapper for the Perl ExifTool
require 'fileutils'
include FileUtils
require 'find'
require 'yaml'
require "time"

require_relative 'lib/SDorHD'
require_relative 'lib/Photo_Naming_Pashua-SD'
require_relative 'lib/Photo_Naming_Pashua–HD'
require_relative 'lib/gpsYesPashua'

puts "RUBY_DESCRIPTION: #{RUBY_DESCRIPTION}\n\n" 