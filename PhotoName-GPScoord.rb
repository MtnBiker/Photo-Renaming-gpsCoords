#!/usr/bin/env ruby
# mini_exiftool couldn't be found. Was a problem with  TM_RUBY, GEM_PATH, AND GEM_HOME not matching the what TextMate is using. TM does not use .ruby_version

# Using GitHub so can use on MBP (laptop)

# Look at https://github.com/txus/kleisli for getting location information from geonames.
# Look at speeding up with https://github.com/tonytonyjan/exif for rename and annotate which is rather slow. 8 min. for 326 photos
# 2019/05/10 installed libexif and tried to use. Got error File not readable or no EXIF data in file. (Exif::NotReadable). Issue still open after two years at tonytonyjan
# puts "Ruby v#{RUBY_VERSION}p#{RUBY_PATCHLEVEL} as reported by Ruby\nAnd as reported by \`system ('gem env')\`:" # A Ruby constant
# system ('gem env') # for debugging problem with gem not loading https://stackoverflow.com/questions/53202164/textmate-chruby-and-ruby-gems

# puts "\n10. Gem.path: #{Gem.path}"
# puts "\ngem list:" # Can't figure out how to do this in one line.
# system ('gem list') # for debugging problem with mini_exiftool not loading

require 'fileutils'
include FileUtils
require 'find'
require 'yaml'
require "time"
# require 'shellwords'
require 'irb' # binding.irb where error checking is desired
require 'mini_exiftool'
# require 'exif' # added later. A partial implementation of ExifTool, but faster than mini_exiftool. Commented out since doesn't work with Panasonic Raw

# require 'geonames' # Brought into the script because was getting loading errors
# The these first three requires are for geonames and then the class
require 'json'
require 'open-uri'
require 'addressable/template' #  gem install addressable
class GeoNames
  class APIError < RuntimeError; end
  OPTIONS = {
    host: 'api.geonames.org',
    time_format: '%Y-%m-%d %T %z',
    timezone: 'UTC',
    username: nil,
    # username: "geonames@web.knobby.ws", # Still got error
  }

  QUERY = {}

  attr_reader :options, :uris

  def initialize(options = {})
    @options = OPTIONS.merge(options)
    @uris = Hash[QUERY.map{|name, args|
      if args.empty?
        template = Addressable::Template.new(
          "http://{host}/#{name}JSON"
        )
      else
        joined = (%w{ username } + args.flatten).uniq.sort.join(',')
        template = Addressable::Template.new(
          "http://{host}/#{name}JSON{?#{joined}}"
        )
      end
      [name, template]
    }]
  end

  # Execute query for given +name+ with +parameters+ translated via URI
  # template expansion.
  def query(name, parameters)
    default = {host: options[:host]}
    default[:username] = options[:username] if options[:username]

    uri = uris[name].expand(default.merge(parameters))

    result =
      if block_given?
        open(uri.to_s){|io| yield(io.read) }
      else
        open(uri.to_s){|io| JSON.parse(io.read) }
      end

    if status = result["status"]
      raise APIError, status.inspect
    else
      result
    end
  end

  # Utility method for some queries that return times, we convert them to real
  # Time instances with proper UTC timezone.
  def fix_datetime(hash)
    if time = hash['datetime']
      zone, format = options.values_at(:timezone, :time_format)
      hash['datetime'] = Time.strptime("#{time} #{zone}", format)
    end

    hash
  end

  # Returns the attribute of the geoNames feature with the given geonameId
  #
  # Parameters: geonameId
  #
  # Example:
  #
  #   api.get(geonameId: 2643743)
  def get(parameters)
    query(:get, parameters)
  end
  QUERY[:get] = %w[geonameId]

  # Returns a list of recent earthquakes, ordered by magnitude
  #
  # north, south, east, west: coordinates of bounding box
  # callback: name of javascript function (optional parameter)
  # date: date of earthquakes 'yyyy-MM-dd', optional parameter
  # minMagnitude: minimal magnitude, optional parameter
  # maxRows: maximal number of rows returned (default = 10)
  #
  # Example:
  #
  #   api.earthquakes(north: 44.1, south: -9.9, east: -22.4, west: 55.2)
  def earthquakes(parameters = {})
    quakes = query(:earthquakes, parameters)['earthquakes']
    quakes.map{|quake| fix_datetime(quake) }
  end
  QUERY[:earthquakes] = %w[
    north south east west date callback minMagnitude maxRows
  ]

  # Elevation - Aster Global Digital Elevation Model
  #
  # Parameters: lat,lng
  #
  # Sample area: ca 30m x 30m, between 83N and 65S latitude.
  # Result: a single number giving the elevation in meters according to aster
  # gdem, ocean areas have been masked as "no data" and have been assigned a
  # value of -9999.
  #
  # Example:
  #
  #   api.astergdem(lat: 50.01, lng: 10.2)
  def astergdem(parameters = {})
    query(:astergdem, parameters)
  end
  QUERY[:astergdem] = %w[lat lng]

  # GTOPO30 is a global digital elevation model (DEM) with a horizontal grid
  # spacing of 30 arc seconds (approximately 1 kilometer). GTOPO30 was derived
  # from several raster and vector sources of topographic information.
  #
  # Parameters: lat,lng
  #
  # Sample area: ca 1km x 1km Result : a single number giving the elevation in
  # meters according to gtopo30, ocean areas have been masked as "no data" and
  # have been assigned a value of -9999.
  #
  # Example:
  #
  #   api.gtopo30(lat: 50.01, lng: 10.2)
  def gtopo30(parameters = {})
    query(:gtopo30, parameters)
  end
  QUERY[:gtopo30] = %w[lat lng]

  # Returns the children for a given geonameId. The children are the
  # administrative divisions within an other administrative division. Like the
  # counties (ADM2) in a state (ADM1) or also the countries in a continent.
  #
  # Parameters:
  # geonameId: the geonameId of the parent
  # maxRows: number of rows returned, default is 200
  #
  # Result: returns a list of GeoName records
  #
  # Example:
  #
  #   api.children(geonameId: 3175395, maxRows: 5)
  def children(parameters = {})
    query(:children, parameters)
  end
  QUERY[:children] = %w[geonameId maxRows]

  # Returns all GeoNames higher up in the hierarchy of a place name.
  #
  # Parameters:
  # geonameId: the geonameId for the hierarchy
  #
  # Result: returns a list of GeoName records, ordered by hierarchy level. The
  # top hierarchy (continent) is the first element in the list
  #
  # Example:
  #
  #   api.hierarchy(geonameId: 2657896)
  def hierarchy(parameters = {})
    query(:hierarchy, parameters)
  end
  QUERY[:hierarchy] = %w[geonameId]

  # Returns all neighbours for a place name (currently only available for
  # countries).
  #
  # Parameters:
  # geonameId: the geonameId for the neighbours
  #
  # Result: returns the neighbours of a toponym, currently only implemented for
  # countries
  #
  # Example:
  #
  #   api.neighbours(geonameId: 2658434)
  def neighbours(parameters = {})
    query(:neighbours, parameters)
  end
  QUERY[:neighbours] = %w[geonameId]

  # Returns all siblings of a GeoNames toponym.
  #
  # Parameters:
  # geonameId: the geonameId for the siblings
  #
  # Result: returns a list of GeoNames records that have the same
  # administrative level and the same father
  #
  # Example:
  #
  #   api.siblings(geonameId: 3017382)
  def siblings(parameters = {})
    query(:siblings, parameters)['geonames']
  end
  QUERY[:siblings] = %w[geonameId]

  # Cities and Placenames
  #
  # Returns a list of cities and placenames in the bounding box, ordered by
  # relevancy (capital/population).
  # Placenames close together are filterered out and only the larger name is
  # included in the resulting list.
  #
  # Parameters:
  # north,south,east,west: coordinates of bounding box
  # callback: name of javascript function (optional parameter)
  # lang: language of placenames and wikipedia urls (default = en)
  # maxRows: maximal number of rows returned (default = 10)
  #
  # Example:
  #
  #   api.cities(north: 44.1, south: -9.9, east: -22.4, west: 55.2, lang: 'de')
  def cities(parameters = {})
    query(:cities, parameters)['geonames']
  end
  QUERY[:cities] = %w[north south east west callback lang maxRows]

  # Weather Stations with most recent Weather Observation
  #
  # Returns a list of weather stations with the most recent weather observation.
  #
  # Parameters:
  # north,south,east,west: coordinates of bounding box
  # callback: name of javascript function (optional parameter)
  # maxRows: maximal number of rows returned (default = 10)
  #
  # Example:
  #
  #   api.weather(north: 44.1, south: -9.9, east: -22.4, west: 55.2)
  def weather(parameters = {})
    observations = query(:weather, parameters)['weatherObservations']
    observations.map{|observation| fix_datetime(observation) }
  end
  QUERY[:weather] = %w[north south east west callbck maxRows]

  # Returns the weather station and the most recent weather observation for the
  # ICAO code.
  #
  # Parameters:
  # ICAO: International Civil Aviation Organization (ICAO) code
  # callback: name of javascript function (optional parameter)
  #
  # Example:
  #
  #   api.weather_icao(ICAO: 'LSZH')
  def weather_icao(parameters = {})
    weather = query(:weatherIcao, parameters)['weatherObservation']
    fix_datetime(weather)
  end
  QUERY[:weatherIcao] = %w[ICAO callback]

  # Country information: Capital, Population, Area in square km, Bounding Box
  # of mainland (excluding offshore islands)

  # Parameters : country (default = all countries)
  # lang: ISO-639-1 language code (en,de,fr,it,es,...) (default = english)
  #
  # Example:
  #
  #   api.country_info(lang: 'it', country: 'DE')
  def country_info(parameters = {})
    query(:countryInfo, parameters)["geonames"]
  end
  QUERY[:countryInfo] = %w[country lang]

  # The ISO country code of any given point.
  #
  # Parameters: lat, lng, type, lang, and radius (buffer in km for closest
  # country in coastal areas)
  #
  # With the parameter type=xml this service returns an xml document with iso
  # country code and country name. The optional parameter lang can be used to
  # specify the language the country name should be in.
  # JSON output is produced with type=JSON, which is the default for this
  # library and will be parsed automatically.
  #
  # Example:
  #
  #   api.country_code(lat: 47.03, lng: 10.2)
  def country_code(parameters = {})
    if parameters[:type].to_s =~ /^xml$/i
      query(:countryCode, parameters){|content| return content }
    else
      query(:countryCode, {type: 'JSON'}.merge(parameters))
    end
  end
  QUERY[:countryCode] = %w[lat lng type lang radius]

  # Country Subdivision / reverse geocoding
  # The ISO country code and the administrative subdivision (state, province, ...) of any given point.
  #
  # Parameters: lat, lng, lang, radius
  #
  # If lang is not given, will return the name in the local language.
  # The radius is measured in km and acts as buffer for closest country in
  # costal areas.
  #
  # Example:
  #
  #   api.country_subdivision(lat: 47.03, lng: 10.2)
  #
  #   # With the parameters 'radius' and 'maxRows' you get the closest
  #   # subdivisions ordered by distance:
  #   api.country_subdivision(lat: 47.03, lng: 10.2, maxRows: 10, radius: 40)
  def country_subdivision(parameters = {})
    query(:countrySubdivision, parameters)
  end
  QUERY[:countrySubdivision] = %w[lat lng lang radius]

  # Ocean / reverse geocoding
  # Returns the name of the ocean or sea for the given latitude/longitude.
  #
  # Parameters : lat,lng
  #
  # Example:
  #
  #   api.ocean(lat: 40.78343, lng: -43.96625)
  def ocean(parameters = {})
    query(:ocean, parameters)["ocean"]
  end
  QUERY[:ocean] = %w[lat lng]

  # Neighbourhood / reverse geocoding
  # The neighbourhood for US cities. Data provided by Zillow under cc-by-sa
  # license.
  #
  # Parameters: lat,lng
  #
  # Example:
  #
  #   api.neighbourhood(lat: 40.78343, lng: -73.96625)
  def neighbourhood(parameters = {})
    query(:neighbourhood, parameters)["neighbourhood"]
  end
  QUERY[:neighbourhood] = %w[lat lng]

  # Elevation - SRTM3
  #
  # Shuttle Radar Topography Mission (SRTM) elevation data. SRTM consisted of a
  # specially modified radar system that flew onboard the Space Shuttle
  # Endeavour during an 11-day mission in February of 2000. The dataset covers
  # land areas between 60 degrees north and 56 degrees south.
  # This web service is using SRTM3 data with data points located every
  # 3-arc-second (approximately 90 meters) on a latitude/longitude grid.
  #
  # Parameters : lat,lng;
  # sample area: ca 90m x 90m Result : a single number giving the elevation in
  # meters according to srtm3, ocean areas have been masked as "no data" and
  # have been assigned a value of -32768.
  #
  # Example:
  #
  #   api.srtm3(lat: 50.01, lng: 10.2)
  def srtm3(parameters = {})
    query(:srtm3, parameters)
  end
  QUERY[:srtm3] = %w[lat lng]

  # The timezone at the lat/lng with gmt offset (1. January) and dst offset (1. July)
  #
  # Parameters: lat, lng, radius (buffer in km for closest timezone in coastal areas)
  # needs username
  #
  # If you want to work with the returned time, I recommend the tzinfo library,
  # which can handle the timezoneId. In order to keep dependencies low and the
  # code flexible and fast, we won't do any further handling here.
  #
  # Example:
  #
  #   api.timezone(lat: 47.01, lng: 10.2)
  def timezone(parameters = {})
    query(:timezone, parameters)
  end
  QUERY[:timezone] = %w[lat lng radius]

  # Find nearby toponym
  #
  # Parameters: lat, lng, featureClass, featureCode,
  # radius: radius in km (optional)
  # maxRows: max number of rows (default 10)
  # style: SHORT, MEDIUM, LONG, FULL (default = MEDIUM), verbosity result.
  #
  # Example:
  #
  #   api.find_nearby(lat: 47.3, lng: 9)
  def find_nearby(parameters = {})
    query(:findNearby, parameters)["geonames"]
  end
  QUERY[:findNearby] = %w[
    lat lng featureClass featureCode radius maxRows style
  ]

  # Returns the most detailed information available for the lat/lng query.
  # It is a combination of several services. Example:
  # In the US it returns the address information.
  # In other countries it returns the hierarchy service: http://ws.geonames.org/extendedFindNearby?lat=47.3&lng=9
  # On oceans it returns the ocean name.
  #
  # Parameters : lat,lng
  #
  # Example:
  #
  #   api.extended_find_nearby(lat: 47.3, lng: 9)
  def extended_find_nearby(parameters = {})
    raise(NotImplementedError, "XML queries haven't been implemented.")
    query(:extendedFindNearby, parameters)
  end
  QUERY[:extendedFindNearby] = %w[lat lng]

  # Find nearby populated place / reverse geocoding
  # Returns the closest populated place for the lat/lng query.
  # The unit of the distance element is 'km'.
  #
  # Parameters:
  # lat, lng,
  # radius: radius in km (optional),
  # maxRows: max number of rows (default 10),
  # style: SHORT, MEDIUM, LONG, FULL (default = MEDIUM), verbosity of result
  #
  # Example:
  #
  #   api.find_nearby_place_name(lat: 47.3, lng: 9)
  def find_nearby_place_name(parameters = {})
    query(:findNearbyPlaceName, parameters)["geonames"]
  end
  QUERY[:findNearbyPlaceName] = %w[lat lng radius maxRows style]

  # List of nearby postalcodes and places for the lat/lng query.
  # The result is sorted by distance.
  #
  # This service comes in two flavors. You can either pass the lat/long or a
  # postalcode/placename.
  #
  # Parameters:
  #
  # lat, lng, radius (in km),
  # maxRows (default = 5),
  # style (verbosity : SHORT,MEDIUM,LONG,FULL),
  # country (default = all countries),
  # localCountry (restrict search to local country in border areas)
  #
  # or
  #
  # postalcode, country, radius (in Km), maxRows (default = 5)
  #
  # Example:
  #
  #   api.find_nearby_postal_codes(lat: 47, lng: 9)
  #   api.find_nearby_postal_codes(postalcode: 8775, country: 'CH', radius: 10)
  def find_nearby_postal_codes(parameters = {})
    query(:findNearbyPostalCodes, parameters)["postalCodes"]
  end
  QUERY[:findNearbyPostalCodes] = %w[
    lat lng radius maxRows style country localCountry postalcode country radius
  ]

  # Returns the nearest street segments for the given latitude/longitude, this
  # service is only available for the US.
  #
  # @param [Float] latitude Latitude
  # @param [Float] longitude Longitude
  #
  # @return [Array] An Array containing zero or more street segments.
  #
  # A street segment has following keys:
  # "adminCode1": Identifier of state.
  # "adminCode2": Area code.
  # "adminName1": Name of state.
  # "adminName2": Name of province.
  # "countryCode": Name of country (usually "US")
  # "distance": Distance of street to given coordinates in km.
  # "fraddl": From address left.
  # "fraddr": From address right.
  # "line": A string with lng/lat points, comma separated.
  # "mtfcc": MAF/TIGER Feature class code.
  # "name:" Name of the street.
  # "postalcode": Postal code of the address.
  # "toaddl": To address left.
  # "toaddr": To address right.
  #
  # @example
  #   api.find_nearby_streets(37.451, -122.18)
  def find_nearby_streets(latitude, longitude)
    [*query(:findNearbyStreets, lat: latitude, lng: longitude)['streetSegment']]
  end
  QUERY[:findNearbyStreets] = %w[lat lng]


  # Find nearby street segments on OpenStreetMap for the given
  # latitude/longitude.
  #
  # @param [Float, String] latitude
  # @param [Float, String] longitude
  #
  # @example
  #   api.find_nearby_streets_osm(37.451, -122.18)
  def find_nearby_streets_osm(latitude, longitude)
    query(:findNearbyStreetsOSM, lat: latitude, lng: longitude)
  end
  QUERY[:findNearbyStreetsOSM] = %w[lat lng]

  # Weather Station with most recent weather observation / reverse geocoding
  # needs username
  #
  # Webservice Type : REST
  # Url : ws.geonames.org/findNearByWeatherJSON?
  # Parameters :
  # lat,lng : the service will return the station closest to this given point (reverse geocoding)
  # callback : name of javascript function (optional parameter)
  #
  # Result : returns a weather station with the most recent weather observation
  #
  # Example http://ws.geonames.org/findNearByWeatherJSON?lat=43&lng=-2
  def find_near_by_weather(parameters = {})
    query(:findNearByWeather, parameters)
  end
  QUERY[:findNearByWeather] = %w[lat lng]

  # Find nearby Wikipedia Entries / reverse geocoding
  #
  # This service comes in two flavors. You can either pass the lat/long or a postalcode/placename.
  # Webservice Type : XML,JSON or RSS
  # Url : ws.geonames.org/findNearbyWikipedia?
  # ws.geonames.org/findNearbyWikipediaJSON?
  # ws.geonames.org/findNearbyWikipediaRSS?
  # Parameters :
  # lang : language code (around 240 languages) (default = en)
  # lat,lng, radius (in km), maxRows (default = 5),country (default = all countries)
  # or
  # postalcode,country, radius (in Km), maxRows (default = 5)
  # Result : returns a list of wikipedia entries as xml document
  # Example:
  # http://ws.geonames.org/findNearbyWikipedia?lat=47&lng=9
  # or
  # ws.geonames.org/findNearbyWikipedia?postalcode=8775&country=CH&radius=10
  def find_nearby_wikipedia(parameters = {})
    query(:findNearbyWikipedia, parameters)
  end
  QUERY[:findNearbyWikipedia] = %w[
    lang lat lng maxRows country postalcode country radius
  ]

  # Find nearest Address
  #
  # Finds the nearest street and address for a given lat/lng pair.
  # Url : ws.geonames.org/findNearestAddress?
  # Parameters : lat,lng;
  # Restriction : this webservice is only available for the US.
  # Result : returns the nearest address for the given latitude/longitude, the street number is an 'educated guess' using an interpolation of street number at the end of a street segment.
  # Example http://ws.geonames.org/findNearestAddress?lat=37.451&lng=-122.18
  #
  # This service is also available in JSON format :
  # http://ws.geonames.org/findNearestAddressJSON?lat=37.451&lng=-122.18
  def find_nearest_address(parameters = {})
    query(:findNearestAddress, parameters)
  end
  QUERY[:findNearestAddress] = %w[lat lng]

  #   Find nearest Intersection
  #
  # Finds the nearest street and the next crossing street for a given lat/lng pair.
  # Url : ws.geonames.org/findNearestIntersection?
  # Parameters : lat,lng;
  # Restriction : this webservice is only available for the US.
  # Result : returns the nearest intersection for the given latitude/longitude
  # Example http://ws.geonames.org/findNearestIntersection?lat=37.451&lng=-122.18
  #
  # This service is also available in JSON format :
  # http://ws.geonames.org/findNearestIntersectionJSON?lat=37.451&lng=-122.18
  def find_nearest_intersection(parameters = {})
    query(:findNearestIntersection, parameters)
  end
  QUERY[:findNearestIntersection] = %w[lat lng]

  # Find nearest street and crossing for a given latitude/longitude pair on
  # OpenStreetMap.
  #
  # @param [Float] latitude
  # @param [Float] longitude
  #
  # @example
  #   api.find_nearest_intersection_osm(37.451, -122.18)
  def find_nearest_intersection_osm(parameters = {})
    query(:findNearestIntersectionOSM, parameters)
  end
  QUERY[:findNearestIntersectionOSM] = %w[lat lng]

  # Postal code country info
  #
  # @return [Array] Countries for which postal code geocoding is available.
  #
  # @example
  #   api.postal_code_country_info
  def postal_code_country_info(parameters = {})
    query(:postalCodeCountryInfo, {})['geonames']
  end
  QUERY[:postalCodeCountryInfo] = []

  # Placename lookup with postalcode
  #
  #
  # @param [Hash] parameters
  # @option parameters [String, Fixnum] :postalcode
  # @option parameters [String] :country
  # @option parameters [Fixnum] :maxRows (20)
  # @option parameters [String] :callback
  # @option parameters [String] :charset ('UTF-8')
  #
  # @return [Array] List of places for the given postalcode.
  #
  # @example
  #   api.postal_code_lookup(postalcode: 6600, country: 'AT')
  def postal_code_lookup(parameters = {})
    query(:postalCodeLookup, parameters)
  end
  QUERY[:postalCodeLookup] = %w[postalcode country maxRows, callback charset]

  # Postal Code Search
  # Returns a list of postal codes and places for the placename/postalcode query.
  #
  # For the US the first returned zip code is determined using zip code area
  # shapes, the following zip codes are based on the centroid. For all other
  # supported countries all returned postal codes are based on centroids.
  #
  # Parameter	Value	Description
  # postalcode	string (postalcode or placename required)	postal code
  # postalcode_startsWith	string	the first characters or letters of a postal code
  # placename	string (postalcode or placename required)	all fields : placename,postal code, country, admin name (Important:urlencoded utf8)
  # placename_startsWith	string	the first characters of a place name
  # country	string : country code, ISO-3166 (optional)	Default is all countries.
  # countryBias	string	records from the countryBias are listed first
  # maxRows	integer (optional)	the maximal number of rows in the document returned by the service. Default is 10
  # style	string SHORT,MEDIUM,LONG,FULL (optional)	verbosity of returned xml document, default = MEDIUM
  # operator	string AND,OR (optional)	the operator 'AND' searches for all terms in the placename parameter, the operator 'OR' searches for any term, default = AND
  # charset	string (optional)	default is 'UTF8', defines the encoding used for the document returned by the web service.
  # isReduced	true or false (optional)	default is 'false', when set to 'true' only the UK outer codes are returned. Attention: the default value on the commercial servers is currently set to 'true'. It will be changed later to 'false'.
  #
  # @example
  #   api.postal_code_search(postalcode: 9011, maxRows: 10)
  def postal_code_search(parameters = {})
    query(:postalCodeSearch, parameters)
  end
  QUERY[:postalCodeSearch] = %w[
    postalcode postalcode_starts placename placename_starts country countryBias
    maxRows style operator charset isReduced
  ]

  # Returns the names found for the searchterm as xml, json, or rdf document,
  # the search is using the AND operator.
  #
  # @param [Hash] parameters
  # @option parameters [String] :q
  #   search over all attributes of a place, place name, country name,
  #   continent, admin codes, ...
  # @option parameters [String] :name
  #   place name only
  # @option parameters [String] :name_equals
  #   exact place name
  # @option parameters [String] :name_startsWith
  #   place name starts with given characters
  # @option parameters [Fixnum] :maxRows (100)
  #   maximum number of results, up to 1000
  # @option parameters [Fixnum] :startRow (0)
  #   used for paging results.
  # @option parameters [String, Array] :country
  #   Country code, ISO-3166 (optional). Default is all countries. May have
  #   more than one country as an Array.
  # @option parameters [String] :countryBias
  #   records from this country will be listed first.
  # @option parameters [String] :continentCode
  #   AF,AS,EU,NA,OC,SA,AN (optional) restricts the search to the given
  #   continent.
  # @option parameters [String] :adminCode1
  #   code of administrative subdivision
  # @option parameters [String] :adminCode2
  #   code of administrative subdivision
  # @option parameters [String] :adminCode3
  #   code of administrative subdivision
  # @option parameters [String, Array] :featureClass
  #   one or more feature class codes, explanation at
  #   http://forum.geonames.org/gforum/posts/list/130.page
  # @option parameters [String, Array] :featureCode
  #   one or more feature class codes, explanation at
  #   http://forum.geonames.org/gforum/posts/list/130.page
  # @option parameters [String] :lang ('en')
  #   ISO-636 2-letter language code; en, de, fr, it, es, ...
  #   place names and country names will be returned in the specified language.
  #   Feature classes and codes are only available in English and Bulgarian.
  # @option parameters [String] :type ('json')
  #   format of returned document.
  # @option parameters [String] :style ('MEDIUM')
  #   verbosity of returned document.
  # @option parameters [String] :isNameRequired (false)
  #   At least one of the search term needs to be part of the place name.
  #   Example: A normal seach for Berlin will return all places within the
  #   state of Berlin. If we only want to find places with 'Berlin' in the name
  #   we se the parameter isNameRequired to `true`. The difference to the
  #   :name_equals parameter is that this will allow searches for 'Berlin,
  #   Germany' as only one search term needs to be part of the name.
  # @option parameters [String] :tag
  #   search for toponyms tagged with the given tag.
  # @option parameters [String] :charset ('UTF8')
  #   encoding of returned document, this wrapper only handles UTF8 for now.
  #
  # @example
  #   api.search(q: 'london', maxRows: 10)
  #   api.search(q: 'london', maxRows: 10, type: 'rdf')
  #   api.search(q: 'skiresort')
  #   api.search(q: 'tags:skiresort')
  #   api.search(q: 'tags:skiresort@marc')
  #
  # With the parameter `type: 'rdf'` the search service returns the result in RDF
  # format defined by the GeoNames Semantic Web Ontology.
  #
  #
  # Tags
  # GeoNames is using a simple tagging system. Every user can tag places. In
  # contrast to the feature codes and feature classes which are one-dimensional
  # (a place name can only have one feature code) several tags can be used for
  # each place name. It is an additional categorization mechanism where the
  # simple classification with feature codes is not sufficient.
  #
  # I have tagged a place with the tag 'skiresort'. You can search for tags
  # with the search: `api.search(q: 'skiresort')` If you only want to search
  # for a tag and not for other occurences of the term (in case you tag
  # something with 'spain' for example), then you add the attribute 'tags:' to
  # the search term: `api.search(q: 'tags:skiresort')`
  #
  # And if you want to search for tags of a particular user (or your own) then
  # you append '@username' to the tag. Like this:
  # `api.search(q: 'tags:skiresort@marc')
  def search(parameters = {})
    query(:search, parameters)['geonames']
  end
  QUERY[:search] = %w[
    q name name_equals name_startsWith maxRows startRow country countryBias
    continentCode adminCode1 adminCode2 adminCode3 featureClass featureCode
    lang type style isNameRequired tag operator charset
  ]

  # Wikipedia articles within a bounding box
  #
  # @param [Hash] parameters
  # @option parameters [Float] :south Southern latitude
  # @option parameters [Float] :north Northern latitude
  # @option parameters [Float] :east Eastern longitude
  # @option parameters [Float] :west Western longitude
  # @option parameters [String] :lang ('en') language
  # @option parameters [Fixnum] :maxRows ('10') maximum number of results
  #
  # @return [Array] The Wikipedia entries found.
  #
  # @example
  #   api.wikipedia_bounding_box(north: 44.1, south: -9.9, east: -22.4, west: 55.2)
  def wikipedia_bounding_box(parameters = {})
    [*query(:wikipediaBoundingBox, parameters)['geonames']]
  end
  QUERY[:wikipediaBoundingBox] = %w[south north east west lang maxRows]

  # Wikipedia Fulltext Search
  #
  # @param [Hash] parameters
  # @option parameters [String] :q
  #   place name
  # @option parameters [String] :title (false)
  #   search in the wikipedia title (optional, true/false)
  # @option parameters [String] :lang ('en')
  #   language
  # @option parameters [Fixnum] :maxRows (10)
  #   maximum number of results
  #
  # @return [Array] The Wikipedia entries found.
  #
  # @example
  #   api.wikipedia_search(q: 'London', maxRows: 10, lang: 'en', title: true)
  #   api.wikipedia_search(q: '秋葉原')
  def wikipedia_search(parameters = {})
    params = parameters.dup
    params[:title] = '' if params[:title] # weird?
    [*query(:wikipediaSearch, params)['geonames']]
  end
  QUERY[:wikipediaSearch] = %w[q title lang maxRows]
end # class GeoNames. Included because something in it won't load right.

require_relative 'lib/gpsYesPashua'
require_relative 'lib/LatestDownloadsFolderEmpty_Pashua'
require_relative 'lib/Photo_Naming_Pashua-SD2'
require_relative 'lib/Photo_Naming_Pashua–HD2'
require_relative 'lib/SDorHD'
require_relative 'lib/renamePashua' # Dialog for renaming without moving
require_relative 'lib/gpsCoordsPashua' # Dialog for adding GPS coordinates without moving
require_relative 'lib/gpsAddLocationPashua' # Dialog for adding location information based GPS coordinates in file EXIF without moving

# For distanceMeters method
RAD_PER_DEG = Math::PI / 180
RM = 6371000 # Earth radius in meters

def lineNum() # Had to move this to above the first call or it didn't work. Didn't think that was necessary
  caller_infos = caller.first.split(":")
  # Note caller_infos[0] is file name
  caller_infos[1]
end # line numbers of this file, useful for debugging and logging info to progress screen

photosArray = [] # can create intially, but I don't know how to add other "fields" to a file already on the list. I'll be better off with an indexed data base. I suppose could delete the existing item for that index and then put in revised. Not using this, but maybe some day
thisScript = File.dirname(__FILE__) +"/" # needed because the Pashua script calling a file seemed to need the directory. 
lastPhotoReadTextFile = "/Volumes/LUMIX/DCIM/" # SD folder alternate since both this and one below occur
sdCardAlt   = "/Volumes/NO NAME/"
sdCard      = "/Volumes/LUMIX/"
srcSDfolderAlt = sdCardAlt + "DCIM/" # SD folder alternate since both this and one below occur. Used at line 740
srcSDfolder = sdCard + "DCIM/"  # SD folder 

# Temp file below that could be used to group some of the searches to geonames
photoArrayFile = thisScript + "currentData/photoArray.txt"
# photoArrayFile = File.join(thisScript + "currentData/photoArray.txt") # change def of thisScript

# Folders on laptop
laptopLocation        = "/Users/gscar/Pictures/_Photo Processing Folders/"
# laptopLocation        = File.join("Users", "gscar", "Pictures", "_Photo Processing Folders") # Should be better than above def
laptopDownloadsFolder = laptopLocation + "Download folder/"
# laptopDownloadsFolder = File.join(laptopLocation , "Download folder") # Hve to go through the entire script and sort out the "/"
laptopDestination     = laptopLocation + "Processed photos to be imported to Mylio/"
laptopDestOrig        = laptopLocation + "Originals to archive/"
laptopTempJpg         = laptopLocation + "Latest Downloads temp jpg/"

# Folders on portable drive: Daguerre. This is the normal location with Daguerre plugged into iMac
downloadsFolders = "/Volumes/Daguerre/_Download folder/"
srcHD     = downloadsFolders + " Drag Photos HERE/"  # Photos copied from camera, sent by others, etc.
destPhoto = downloadsFolders + "Latest Processed photos-Import to Mylio/" # Was Latest Download. These are relabeled and GPSed files.
tempJpg   = downloadsFolders + "Latest Downloads temp jpg/"
destOrig  = downloadsFolders + "_imported-archive" # folder to move originals to if not done in. No slash because getting double slash with one
srcRename = "/Volumes/Seagate 8TB Backup/Mylio_87103a/Greg Scarich’s iPhone Library/" # Frequent location to perfom this. iPhone photos brought into Mylio
#  Below is temporary file location for testing
srcGpsAdd = "/Users/gscar/Documents/◊ Pre-trash/Cheeseboro/" # srcRename # Could to another location for convenience
srcAddLocation  = "/Volumes/Daguerre/_Download folder/Latest Processed photos-Import to Mylio/" # = srcRename # Change to another location for convenience. This location picked so don't screw up a bunch of files

# Mylio folder. Moved to this folder after all processing. Can't process in this folder or Mylio might add before this script's processing is finished. Processing is mainly done in destPhoto (should rename to ?, not process photo since that is another folder)
iMacMylio = "/Users/gscar/Mylio/2021/GX8-2021/"

lastPhotoReadTextFile = thisScript + "currentData/lastPhotoRead.txt"
puts "#{lineNum}. lastPhotoReadTextFile: #{lastPhotoReadTextFile}. ?? But it's being stored on LUMIX card"

# geoInfoMethod = "wikipedia" # for gpsPhoto to select georeferencing source. wikipedia—most general and osm—maybe better for cities # not being used May 2019
timeZonesFile = "/Users/gscar/Dropbox/scriptsEtc/Greg camera time zones.yml"
# timeZones = YAML.load(File.read(timeZonesFile)) # read in that file now and get it over with. Only use once, so this just confused things
gpsPhotoPerl = thisScript + "lib/gpsPhoto.pl"
folderGPX = "/Users/gscar/Dropbox/ GPX daily logs/2021 Massaged/" # Could make it smarter, so it knows which year it is. Massaged contains gpx files from all locations whereas Downloads doesn't. This isn't used by perl script
puts "#{lineNum}. Must manually set folderGPX for GPX file folders. Particularly important at start of new year AND if working on photos not in current year.\n       Using: #{folderGPX}\n"
geoNamesUser    = "MtnBiker" # This is login, user shows up as MtnBiker; but used to work with this. Good but may use it up. Ran out after about 300 photos per hour. This fixed it.
geoNamesUser2   = "geonamestwo" # second account when use up first. Or use for location information, i.e., splitting use in half. NOT IMPLEMENTED

# Allowing options do only do partial changes. Used to have this but took out.
gpsDo = false # Haven't implemented
locationDo = false

# MODULES
def ignoreNonFiles(item) # invisible files that shouldn't be processed
  # puts "#{lineNum}. item: #{item}. item.slice(0,6): #{item.slice(0,7)}"
  item == '.' or item == '..' or item == '.DS_Store' or item == 'Icon ' or item.slice(0,7) == ".MYLock"
  # .MYLock... is a Mylio file of some kind
  # This is true when it should not be processed i.e. next if ignoreNonFiles(item) == true
  # next if ignoreNonFiles(item) == true # how to use this
end

def gpsFilesUpToDate(folderGPX)
  # Find latest file, will have to be alphabetical order since creation date is date copied to drive.
  # Check date of file with current date, i.e. parse the file name. 
  # Compare and report.
  # Have to do after select location of files
end

def timeStamp(timeNowWas, fromWhere)  
  seconds = Time.now-timeNowWas
  minutes = seconds/60
  if minutes < 2
    report = "#{lineNum}. #{seconds.to_i} seconds"
  else
    report = "#{lineNum}. #{minutes.to_i} minutes"
  end   
  puts "\n#{fromWhere} -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -   #{report}. #{Time.now.strftime("%I:%M:%S %p")}   -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  "
  Time.now
end

def whichOne(whichOne)  # suspect could do without this with minor changes
  if whichOne =="S" # First letter of this option
    whichOne = "SD"
  # elsif whichOne == "R" # Rename
  #   whichOne = "Rename"
  else # Hard drive
    whichOne = "HD"
  end 
  whichOne  
end

def whichSource(whichOne,prefsPhoto)
  case whichOne
  when SD
    src = prefsPhoto["srcSelect"]  + "/"
  when HD
    src = prefsPhoto["srcSelect"]  + "/"
  end
  src
end

 def copySD(src, srcHD, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) 
  # some of the above counter variables could be set at the beginning of this script and used locally
  puts "\n#{lineNum}. Copying photos from an SD card starting with #{lastPhotoFilename} or from another value manually entered"
  cardCount = 0
  cardCountCopied = 0
  doAgain = true # name isn't great, now means do it. A no doubt crude way to run back through the copy loop if we moved to another folder.
  # timesThrough = 1
  fileSDbasename = "" # got an error at puts fileSDbasename
  while doAgain==true # and timesThrough<=2 
    Dir.chdir(src) # needed for glob
    Dir.glob("P*") do |item| 
      cardCount += 1
      print(".") # crude activity bar. This doesn't happen
      # put cardCount # another try at activity bar
      # puts "#{lineNum}.. src/item: #{src}#{item}."
      fn = src + "/" + item # 2019.05.08 added /. Hadn't had it before. Maybe the problem is with src
      fnp = srcHD + "/" + item # using srcHD as the put files here place, might cause problems later
      # get filename and make select later than already downloaded
      fileSDbasename = File.basename(item,".*")
      # puts "#{lineNum}. #{cardCount}. item: #{item}. fn: #{fn}"
      next if item == '.' or item == '..' or fileSDbasename <= lastPhotoFilename # don't need the first two with Dir.glob, but doesn't slow things down much overall for this script
      FileUtils.copy(fn, fnp) # Copy from card to hard drive. , preserve = true gives and error. But preserve also preserves permissions, so that may not be a good thing. If care will have to manually change creation date
      cardCountCopied += 1
    end # Dir.glob("P*") do |item| 
      # write the number of the last photo copied or moved
      # if fileSDbasename ends in 999, we need to move on to the next folder, and the while should allow another go around.
    doAgain = false
    if fileSDbasename[-3,3]=="999" # and NEXT PAIRED FILE DOES NOT EXIST, then can uncomment the two last lines of this if, but may also have to start the loop over, but it seems to be OK with mid calculation change.
        nextFolderNum = fileSDbasename[-7,3].to_i + 1 # getting first three digits of filename since that is also part of the folder name
        nextFolderName = nextFolderNum.to_s + "_PANA"
        
        # This begin rescue end not needed since now getting folder name from file name
        # begin
        #   # Writing which folder we're now in
        #   # fileNow = File.open(thisScript + sdFolderFile, "w") # Was 2014.02.28 How could this have worked?
        #   fileNow = File.open(sdFolderFile, "w")
        #   fileNow.write(nextFolderName)
        # rescue IOError => e
        #   puts "Something went wrong. Could not write last photo read (#{nextFolderName}) to #{sdFolderFile}"
        # ensure
        #     fileNow.close unless fileNow == nil
        # end # begin writing sdFolderFile
        # puts "\n#{nextFolderName} File.exist?(nextFolderName): #{File.exist?(nextFolderName)}" 
        src = srcSDfolder + nextFolderName + "/"
        if File.exist?(src)
          doAgain = true
        else
          doAgain = false
        end     
        puts "#{lineNum}. Now copying from #{src} as we finished copying from the previous folder.\n"
    end
  end # if doAgain…
  # Writing which file on the card we ended on
  firstLine = fileSDbasename + " was the last file read on " + Time.now.to_s
  begin
    file_prepend(lastPhotoReadTextFile, firstLine)
    # Following just puts in the last file and wipes out the rest. Can delete all of this
    # fileNow = File.open(lastPhotoReadTextFile, "w") # must use explicit path, otherwise will use wherever we are are on the SD card
    #   fileNow.puts firstLine
    #   fileNow.close
      puts "\n#{lineNum}. The last file processed. fileSDbasename, #{fileSDbasename}, written to  # {fileNow} ??."
  rescue IOError => e
    puts "Something went wrong. Could not write last photo read (#{fileSDbasename}) to #{fileNow}"
  end # begin
    puts "\n#{lineNum}. Of the #{cardCount} photos on the SD card, #{cardCountCopied} were copied to #{src}" #last item was src, doesn't make sense
end # copySD

def uniqueFileName(filename)
  # https://www.ruby-forum.com/topic/191831#836607
  count = 0
  unique_name = filename
  while File.exists?(unique_name)
    count += 1
    unique_name = "#{File.join(File.dirname(filename),File.basename(filename, ".*"))}-#{count}#{File.extname(filename)}"
  end
  unique_name
end

def copyAndMove(srcHD, destPhoto, tempJpg, destOrig, photosArray)
  puts "\n#{lineNum}. Copy photos\nfrom #{srcHD}\n  to #{destPhoto} where the renaming will be done, \n\n and the originals moved to an archive folder (#{destOrig})\n Running dots are progress bar" 
  # Only copy jpg to destPhoto if there is not a corresponding raw, but keep all taken files. With Panasonic JPG comes before RW2
  # Guess this method is slow because files are being copied
  # THIS METHOD WILL NOT WORK IF THE RAW FILE FORMAT ALPHABETICALLY COMES BEFORE JPG. SHOULD MAKE THIS MORE ROBUST
  photoFinalCount = 0
  delCount = 1
  itemPrev = "" # need something for first time through
  fnp = "" # when looped back got error "undefined local variable or method ‘fnp’ for main:Object", so needs to be set here to remember it. Yes, this works, without this statement get an error
  jpgMove = false # Define outside of the 'each do' loop
  # puts "#{lineNum}. Files in #{srcHD}: #{Dir.entries(srcHD).sort}" # list of files to be processed
  Dir.entries(srcHD).sort.each do |item| # This construct goes through each in order. Sometimes the files are not in order with Dir.foreach or Dir.entries without sort
    # Item is the file name
    # puts "\n#{lineNum}.. photoFinalCount: #{photoFinalCount + 1}. item: #{item}." # kind of a progress bar
    next if item == '.' or item == '..' or item == '.DS_Store'
    # next if ignoreNonFiles(item) == true
    # fileExt = File.extname(item)
    # I think the following if is about not bringing jpg's into whatever program I'm using which is now Mylio. Now being used at the moment, so all commented out
    if File.basename(itemPrev, ".*") == File.basename(item,".*") && photoFinalCount != 0
     #  The following shouldn't be necessary, but is a check in case another kind of raw or who know what else. Only the FileUtils.rm(itemPrev) should be needed
     itemPrevExtName = File.extname(itemPrev) # since reusing below
     # TODO Add an option to keep or not keep jpgs. May want to see how camera is converting them. May end up having problem with labeling as then would have two photos taken at the same time and the Raw will always be a .b
     # Now just keeping them
       # FileUtils.rm(destPhoto + itemPrev) if itemPrevExtName == ".HEIC" # could uncomment this if a problem for Mylio.
        # All the commented out lines below since keeping jpgs. Not sure about what how to handle HEIC
      if itemPrevExtName.downcase ==  ".jpg" # Downcased and removed this (".JPG" or itemPrevExtName ==) added lower case for iPhone to sort HEIC
        # Mark for moving to tempJpg
        jpgMove = true
        # FileUtils.rm(fnp) # Removing the jpg file from LatestDownload which is "duplicate" of a RAW that we're now considering. Can comment this out to keep both
        # puts "#{lineNum}.. #{delCount}. fnp: #{itemPrev} will not be transferred because it's a jpg duplicate of a RAWversion." # Is this slow? Turned off to try. Not sure.
        # puts "#{lineNum}.. #{delCount}. fnp: #{itemPrev} was moved to #{tempJpg} it's a jpg duplicate of a RAW version and needs to be processed separately." # Is this slow? Turned off to try. Not sure.
        delCount += 1
        # photoFinalCount -= 1 # commented out since now included
      elsif # not a jpg and check for HEIC--what am I doing with this
        if itemPrevExtName == ".HEIC"
          FileUtils.rm(destPhoto + itemPrev)
        end # itemPrevExtName-just one line
        puts "#{lineNum}. Something very wrong here with trying to remove JPGs when there is a corresponding .RW2 or .HEIC. itemPrev: #{itemPrev}. item: #{item}."
      end # itemPrevExtName.downcase a bunch of lines
      # end # File.extname  
    end   # File.basename
    fn  = srcHD     + item # sourced from Drag Photos Here
    fnp = destPhoto + item # new file in Latest Download
    fnp = tempJpg   + item if !jpgMove # seems like ! is backwards but this works
    # puts "#{lineNum}. Copy from fn: #{fn}"  # debugging
    fnf = destOrig  + item # to already imported for archiving
    # puts "#{lineNum}. to fnp: #{fnp}" # debugging
    FileUtils.copy(fn, fnp) if fn!=fnp # making a copy in the Latest Downloads folder for further action
    # puts "#{lineNum}.#{photoFinalCount}. #{fn} copied to #{fnp}" # dubugging
    # puts "#{lineNum}.#{photoFinalCount}. item: #{item}. #{fn} copied to #{fnp}" # dubugging

    if File.exists?(fnf)  # moving the original to _imported-archive, but not writing over existing files
      fnf = uniqueFileName(fnf)
      FileUtils.move(fn, fnf)
      puts "#{lineNum}. A file already existed with this name so it was changed to fnf: #{fnf}"
    else # no copies, so move
      # puts "#{lineNum}.#{photoFinalCount}. #{fn} moved to #{fnf}" # dubugging
      FileUtils.move(fn, fnf)
    end # File.exists?
    # "#{lineNum}.. #{photoFinalCount + delCount} #{fn}" # More for debugging, but maybe OK as progress in this slow process
    itemPrev = item
    jpgMove = false
    photoFinalCount += 1
    arrayIndex = photoFinalCount - 1 # Need spaces around the minus
    photosArray << [arrayIndex, item, fnp, itemPrevExtName] # count minus one, so indexed like an array starting at zero
    print "." # Trying to get a progress bar
  end # Dir.entries
  # puts "\#{lineNum}. #{photoFinalCount} photos have been moved and are ready for renaming and gpsing. #{delCount-1} duplicate jpg were not
  if delCount > 1
#   comment = "#{lineNum}. #{delCount-1} duplicate jpg were not moved."
    comment = "#{lineNum}. #{delCount-1} jpegs were moved to #{tempJpg} for processing separately."
  else
    comment = ""
  end # if delCount
  puts "\n#{lineNum}. #{photoFinalCount} photos have been moved and are ready for renaming and adding GPS coordinates and locations \n#{comment}"
  return photosArray
end # copyAndMove: copy to the final destination where the renaming will be done and the original moved to an archive (_imported-archive folder)

# def unmountCard(card)
#   puts "#{lineNum}. card: #{card}"
#   card = card[-8, 7]
#   puts "#{lineNum}. card: #{card}"
#   card  = "\"" + card + "\""
#   disk =  `diskutil list |grep #{card} 2>&1`
#   puts "\n#{lineNum}. disk: #{disk}"
#   # Getting confused because grabbing the last 7 twice. And naming sucks (mjy fault)
#   driveID = disk[-8, 7] # not sure this syntax is precise, but it's working.
#   puts "#{lineNum} Unmount #{card}. May have to code this better. See if card name is already a variable. This is hard coded for a specific length of card name"
#   puts "#{lineNum}. driveID: #{driveID}. card: #{card}"
#   cmd =  "diskutil unmount #{driveID} 2>&1"
#   puts "cmd: #{cmd}"
#   unmountResult = `diskutil unmount #{driveID} 2>&1`
#   puts "\n#{lineNum}. SD card, #{unmountResult}, unmounted."
# end #unm

def userCamCode(fn)
  fileEXIF = MiniExiftool.new(fn)
  ## not very well thought out and the order of the tests matters
  case fileEXIF.model
    when "DMC-GX8"
      userCamCode = ".gs.P" # gs for photographer. P for *P*anasonic Lumix
    when "iPhone X"
      userCamCode = ".i" # gs for photographer. i for iPhone
    when "Canon PowerShot S100"
      userCamCode = ".lb" # initials of the photographer who usually shoots with the S100
    when "DMC-GX7" # no longer using, but may reprocess some photos
      userCamCode = ".gs.P" # gs for photographer. P for *P*anasonic Lumix
    when "DMC-TS5"
      userCamCode = ".gs.W" # gs for photographer. W for *w*aterproof Panasonic Lumix DMC-TS5/
    else
      userCamCode = ".xx"
  end # case
  if fileEXIF.fileType(fn) == "??"
    userCamCode = ".gs.L"
  end
  if fileEXIF.fileType(fn) == "AVI" # is this for Canon video ?
    userCamCode = ".lb.c"
  end
  return userCamCode
end # userCamCode

def fileAnnotate(fn, fileEXIF, fileDateTimeOriginalstr, tzoLoc)  # writing original filename and dateTimeOrig to the photo file.
  # Called from rename
  # writing original filename and dateTimeOrig to the photo file.
  # SEEMS SLOPPY THAT I'M OPENING THE FILE ELSEWHERE AND SAVING IT HERE
  if fileEXIF.source.to_s.length < 2 # if exists then don't write. If avoid rewriting, then can eliminate this test. Was a test on comment, but not sure what that was and it wasn't working.
    # puts "#{lineNum}. tzoLoc #{tzoLoc}"
    if tzoLoc.to_i < 0
      tzoLocPrint = tzoLoc
    else
      tzoLocPrint = "+" + tzoLoc.to_s
    end
    fileEXIF.instructions = "#{fileDateTimeOriginalstr} #{tzoLocPrint}" if !fileEXIF.DateTimeStamp # Time zone of photo is GMT #{tzoLoc} unless TS5?" or travel. TODO find out what this field is really for
    # fileEXIF.comment = "Capture date: #{fileDateTimeOriginalstr} UTC. Time zone of photo is GMT #{tzoLoc}. Comment field" # Doesn't show up in Aperture
    # fileEXIF.source = fileEXIF.title = "#{File.basename(fn)} original filename" # Source OK, but Title seemed a bit better
    fileEXIF.source = "#{File.basename(fn)}"
    fileEXIF.TimeZoneOffset = tzoLoc # Time Zone Offset, (1 or 2 values: 1. The time zone offset of DateTimeOriginal from GMT in hours, 2. If present, the time zone offset of ModifyDate)
    # Am I misusing this? I may using it as the TimeZone for photos taken GMT 0 TODO
    # OffsetTimeOriginal	(time zone for DateTimeOriginal) which may or may not be the time zone the photo was taken in TODO 
    # TODO write GMT time to
    # Wiping out bad GPS data on TS5. Maybe should test for TS5 to save checking all other files
    if !fileEXIF.GPSDateTime  # i.e. == "false" # condition if bad data for TS5. Note is nil for GX7. Not changing because can use as flag
      # puts "#{lineNum}. #{File.basename(fn)} has bad GPS data  (GPSDateTime is false), and will be blanked out\n"
      fileEXIF.gps_latitude = fileEXIF.gps_longitude = fileEXIF.gps_altitude = ""
    end    
    fileEXIF.save
  end
end # fileAnnotate. writing original filename and dateTimeOrig to the photo file and cleaning up TS5 photos with bad (no) GPS data.

# With the fileDateTimeOriginal for the photo, find the time zone based on the log.
# The log is in numerical order and used as index here. The log is a YAML file
def timeZone(fileDateTimeOriginal, timeZonesFile )
  # theTimeAhead = "2050-01-01T00:00:00Z"
  # puts "#{lineNum}. timeZones:  #{timeZones}."
  timeZones = YAML.load(File.read(timeZonesFile)) # should we do this once somewhere else? Let's try that in this new version
  # puts "#{lineNum}. timeZones.keys:  #{timeZones.keys}."
  i = timeZones.keys.max # e.g. 505
  j = timeZones.keys.min # e.g. 488
  while i > j # make sure I really get to the end 
    theTime = timeZones[i]["timeGMT"]
    # puts "\n#{lineNum}. (last entry in timeZonesFile) i: #{i}. theTime (of the last entry in GMT): #{theTime}. theTime.class: #{theTime.class}" # i: 502. theTime: 2011-06-29T01-00-00Z. theTime.class: String
    theTime = Time.parse(theTime) # class: time Wed Jun 29 00:00:00 -0700 2011. Time.parse only seems to do the date part
    # puts "\n#{lineNum}. #{i}. fileDateTimeOriginal: #{fileDateTimeOriginal}. theTime (in local time): #{theTime}. fileDateTimeOriginal.class: #{theTime.class}. fileDateTimeOriginal.class: #{theTime.class}"
    # puts "Note that these dates are supposed to be UTC, but are getting my local time zone attached."
    if fileDateTimeOriginal.to_s > theTime.to_s # What if neither was to_s? TODO
      theTimeZone = timeZones[i]["zone"]
      # puts "C. #{i}. fileDateTimeOriginal: #{fileDateTimeOriginal} fileDateTimeOriginal.class: #{fileDateTimeOriginal.class}. theTimeZone: #{theTimeZone}."
      return theTimeZone
    else
      i= (i.to_i-1).to_s
    end
  end # loop
  # theTimeZone = -2 # Was changed on MBP, don't know if needed there or it was a one off
  # puts "#{lineNum}. #{i}. fileDateTimeOriginal: #{fileDateTimeOriginal} fileDateTimeOriginal.class: #{fileDateTimeOriginal.class}. theTimeZone: #{theTimeZone}. "  return theTimeZone
end # timeZone

def rename(src, timeZonesFile, timeNowWas)
  # src is destPhoto folder
  # timeZonesFile is my log of which time zones I was in when
  # timeNowWas used for timing various parts of the script. 
  # Until 2017, this assumed camera on UTC, but doesn't work well for cameras with a GPS or set to local time
  # So have to ascertain what time zone the camera is set to by other means in this script, none of them foolproof
  # 60 minutes for ~1000 photos to rename TODO ie, very slow
  fn = fnp = fnpPrev = "" # must declare variable or they won't be available everywhere in the module
  subSecPrev = subSec = ""
  fileDatePrev = ""
  dupCount = 0
  count    = 0
  tzoLoc = ""
  seqLetter = %w(a b c d e f ) # used when subsec doesn't exist
  # puts "#{lineNum}. Entered rename and ready to enter foreach. src: #{src}"
 #  puts "#{lineNum}. Dir.entries(src). #{Dir.entries(src)}" # Debugging. Turned out I was trying to work on an empty folder.
  Dir.foreach(src) do |item| # for each photo file
    next if ignoreNonFiles(item) == true # skipping file when true, i.e., not a file
    # puts "#{lineNum}. File skipped because already renamed, i.e., the filename starts with 20xx #{item.start_with?("20")}"
    # end
    next if item.start_with?("20") # Skipping files that have already been renamed.
    next if item.end_with?("xmp") # Skipping .xmp files in Mylio and elsewhere. The files may become orphans
    # puts "#{lineNum}. #{item} will be renamed. " # #{timeNowWas = timeStamp(timeNowWas)}
    fn = src + item # long file name
    fileEXIF = MiniExiftool.new(fn) # used several times
    # fileEXIF = Exif::Data.new(fn) # see if can just make this change, probably break something. 2017.01.13 doesn't work with Raw, but developer is working it.
    camModel = fileEXIF.model
    # puts "\n#{lineNum}. #{fileCount}. fn: #{fn}"
    # puts "#{lineNum}.. File.file?(fn): #{File.file?(fn)}. fn: #{fn}"
    # if !File.file?(fn) # Take out when figure it out.
    #   puts "#{lineNum}. Checking why the check below is needed. File.file?(fn): #{File.file?(fn)} for fn: #{fn}"
    # end
    if File.file?(fn) # why is this needed. Do a check above
      # Determine the time and time zone where the photo was taken
      # puts "#{lineNum}.. fn: #{fn}. File.ftype(fn): #{File.ftype(fn)}." #  #{timeNowWas = timeStamp(timeNowWas)}
      fileExt = File.extname(fn).tr(".","").downcase  # needed later for determining if dups at same time. Will be lowercase jpg or rw2 or whatever
      fileExtPrev = ""
      fileDateTimeOriginal = fileEXIF.dateTimeOriginal # The time stamp of the photo file, maybe be UTC or local time (if use Panasonic travel settings). class time, but adds the local time zone to the result
      fileSubSecTimeOriginal = fileEXIF.SubSecTimeOriginal # no error if doesn't exist
      subSec = "." + fileSubSecTimeOriginal.to_s[0..1] #Truncating to 2 figs (could round but would need to make a float, divide by 10 and round or something. This should be close enough)
      subSecExists = fileEXIF.SubSecTimeOriginal.to_s.length > 2 # 
      if fileDateTimeOriginal == nil 
        # TODO This probably could be cleaned up, but then normally not used, movie files don't have this field
        fileDateTimeOriginal = fileEXIF.DateCreated  # PNG don't have dateTimeOriginal
        camModel ="MISC" # Dummy value for test below
        fileDateTimeOriginal == nil ? fileDateTimeOriginal = fileEXIF.CreationDate : "" # now fixing .mov files
        fileDateTimeOriginal == nil ? fileDateTimeOriginal = fileEXIF.MediaCreateDate : "" # now fixing .mp4 files. Has other dates, but at least for iPhone mp4s the gps info exists
      end # if fileDateTimeOriginal == nil
      panasonicLocation = fileEXIF.location # Defined by Panasonic if on trip (and also may exist for photos exported from other apps such as Photos). If defined then time stamp is that local time
      # puts "#{lineNum}. panasonicLocation: #{panasonicLocation}"
      tzoLoc = timeZone(fileDateTimeOriginal, timeZonesFile ) # the time zone the picture was taken in, doesn't say anything about what times are recorded in the photo's EXIF. I'm doing this slightly wrong, because it's using the photo's recorded date which could be either GMT or local time. But only wrong if the photo was taken too close to the time when camera changed time zones
      puts "#{lineNum}. tzoLoc: #{tzoLoc}. count: #{count}" # added in MBP
      if count == 1 | 1*100
        puts "#{lineNum}. panasonicLocation: #{panasonicLocation}. tzoLoc: #{tzoLoc} Time zone photo was taken in from Greg camera time zones.yml"
      else
        print "."
      end # count
      # count == 1 | 1*100 ?  :  puts "."  Just to show one value, otherwise without if prints for each file; now prints every 100 time since this call seemed to create some line breaks and added periods.
      # Also determine Time Zone TODO and write to file OffsetTimeOriginal	(time zone for DateTimeOriginal). Either GMT or use tzoLoc if recorded in local time as determined below
      # puts "#{lineNum}.. camModel: #{camModel}. #{tzoLoc} is the time zone where photo was taken. Script assumes GX8 on local time "
      # Could set timeChange = 0 here and remove from below except of course where it is set to something else
      timeChange = 0 # setting it outside the loops below and get reset each time through. But can get changed
      # puts "#{lineNum}. camModel: #{camModel}. fileEXIF.OffsetTimeOriginal: #{fileEXIF.OffsetTimeOriginal}"
      if camModel ==  "MISC" # MISC is for photos without fileDateTimeOriginal, e.g., movies
        # timeChange = 0
        fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
      elsif camModel == "DMC-TS5" or camModel == "DMC-GX8"
      # elsif camModel.include?("DMC-GX7") and panasonicLocation.length > 0 or camModel == "DMC-TS5" or camModel == "DMC-GX8" # Not sure what the first check was, but GX& isn't being used anymore so took it out. Was giving an error for a jpg created by QuickTime Player 2021.07.15. DateTimeOriginal is in local time. Look at https://sno.phy.queensu.ca/~phil/exiftool/TagNames/Panasonic.html for other Tags that could be used
        # Above first checking that is a Panasonic Lumix GX7 using travel, otherwise will error on second test which checks if using travel, 
        ### first criteria won't work for files exported from another app using GX7
        # timeChange = 0
        fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
#       puts "#{lineNum}: camModel: #{camModel}. tzoLoc: #{tzoLoc}. timeChange.class: #{timeChange.class} timeChange: #{timeChange.to_i}"
      elsif camModel == "iPhone X"  # DateTimeOriginal is in local time
        # timeChange = 0
        fileEXIF.OffsetTimeOriginal = tzoLoc.to_s
        timeChange = (3600*tzoLoc) # previously had error capture on this. Maybe for general cases which I'm not longer covering
        fileEXIF.OffsetTimeOriginal = "GMT"
      end # if camModel
      puts "#{lineNum}.. fileDateTimeOriginal #{fileDateTimeOriginal}. timeChange: #{timeChange}"

      fileDate = fileDateTimeOriginal + timeChange.to_i # date in local time photo was taken. No idea why have to change this to i, but was nil class even though zero  
      fileDateTimeOriginalstr = fileDateTimeOriginal.to_s[0..-6]

      # filePrev = fn
      # Working out if files at the same time
      # puts "\nxx.. #{fileCount}. oneBack: #{oneBack}."
      # Determine dupCount, i.e., 0 if not in same second, otherwise the number of the sequence for the same time
      # puts "#{lineNum}.. #{timeStamp(timeNowWas)}"
      # Now the fileBaseName. Simple if not in the same second, otherwise an added sequence number
      # oneBack = fileDate == fileDatePrev # true if previous file at the same time calculated in local time
      oneBack = fileDate == fileDatePrev && fileExt != fileExtPrev # at the moment this is meaningless because all ofne type
      # puts "\n#{lineNum}.#{count}. oneBack: #{oneBack}. #{item}. dupCount: #{dupCount}"
      # if subSecExists # mainly GX8. Too heavy handed, every GX8 files get subSec which is too much
#           fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") + "." + fileSubSecTimeOriginal.to_s + userCamCode(fn)
#           puts "#{lineNum}. fn: #{fn} in 'if subSecExists'.     fileBaseName: #{fileBaseName}."
      # else # not GX8
      if oneBack # at the moment only handles two in the same second
        dupCount += 1
        if subSecExists # mainly GX8. and maybe iPhone bursts
          fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  subSec + userCamCode(fn) # this doesn't happen for the first one in the same second.
          # puts "#{lineNum}. fn: #{fn} in 'if subSecExists'.     fileBaseName: #{fileBaseName}. dupCount: #{dupCount}"
          if dupCount == 1
            # Can use old fileDate because it's the same and userCamCode. 
            fnp = src + fileDate.strftime("%Y.%m.%d-%H.%M.%S") + subSecPrev + userCamCode(fn)+  File.extname(fn).downcase
            # puts "#{lineNum}. We will relabel #{fnpPrev} to #{fnp} since it didn't get subSecPrev: #{subSecPrev}. dupCount: #{dupCount} "
            File.rename(fnpPrev,fnp)
          end # if dup count
        else # photos without subsecs, pre GX8
          fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  seqLetter[dupCount] + userCamCode(fn)
          puts "#{lineNum}. fn: #{fn} in 'if oneBack'.     fileBaseName: #{fileBaseName}."
        end # subSecExists
        # fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S") +  seqLetter[dupCount] + userCamCode(fn)
#           puts "#{lineNum}. fn: #{fn} in 'if oneBack'.     fileBaseName: #{fileBaseName}."
      else # normal condition that this photo is at a different time than previous photo
        dupCount = 0 # resets dupCount after having a group of photos in the same second
        fileBaseName = fileDate.strftime("%Y.%m.%d-%H.%M.%S")  + userCamCode(fn)
        # puts "#{lineNum}. item: #{item} is at different time as previous.    fileBaseName: #{fileBaseName}"
      end # if oneBack
      # end # if subSecExists
      fileDatePrev = fileDate
      fileExtPrev = fileExt
      # fileBaseNamePrev = fileBaseName
   
      # File renaming and/or moving happens here
      # puts "#{lineNum}. #{count+1}. dateTimeOriginal: #{fileDateTimeOriginal}. item: #{item}. camModel: #{camModel}" # . #{timeNowWas = timeStamp(timeNowWas)} # took 1 sec per file
      fileAnnotate(fn, fileEXIF, fileDateTimeOriginalstr, tzoLoc) # adds original file name, capture date and time zone to EXIF. Comments which I think show up as instructions in Aperture. Also wiping out bad GPS data on TS5
      fnp = fnpPrev = src + fileBaseName + File.extname(fn).downcase # unless #Why was the unless here?
      # puts "Place holder to make the script work. where did the unless come from"
#       puts "#{lineNum}. fn: #{fn}. fnp (fnpPrev): #{fnp}. subSec: #{subSec}"
      subSecPrev = subSec.to_s
      File.rename(fn,fnp)
      count += 1
      # print " #{count}" Trying for  progress indicator
      # puts "#{lineNum}.#{count} #{timeNowWas = timeStamp(timeNowWas)}. #{fileBaseName}" # temp to see how long taking. 1 to 4 seconds on MBP accessing photos on attached portable drive
    else
      puts "#{lineNum}. CHECKING why `if File.file?(fn)` is needed. File.file?(fn): #{File.file?(fn)} for fn: #{fn}"
    end # 3. if File.file?(fn)
    # puts "#{lineNum}. Got to here. tzoLoc: #{tzoLoc}"
    
  end # 2. Dir.foreach(src)
  # return tzoLoc # used by ?
  # puts "#{lineNum}. Got to here. tzoLoc: #{tzoLoc}" # tzoLoc doesn't exist here
  return tzoLoc # the time zone the picture was taken in,
end # rename ing photo files in the downloads folder and writing in original time.

def addCoordinates(destPhoto, folderGPX, gpsPhotoPerl, tzoLoc)
  # Remember writing a command line command, so telling perl, then which perl file, then the gpsphoto.pl script options
  # --timeoffset seconds     Camera time + seconds = GMT. No default.  
  # maxTimeDiff = 50000 # seconds, default 120, but I changed it 2011.07.26 to allow for pictures taken at night but GPS off. Distance still has to be reasonable, that is the GPS had to be at the same place in the morning as the night before as set by the variable below
  # This works, put in because having problems with file locations
  # perlOutput = `perl \"#{gpsPhotoPerl.shellescape}\" --dir #{destPhoto.shellescape} --gpsdir #{folderGPX.shellescape} --timeoffset 0 --maxtimediff 50000 2>&1`

# Assuming all the photos are from the same camera, get info on one and use that information. destPhoto is where they are. Can I get the third file in the folder (to avoid)
# GX7 is UST
# TS5. Need to determine time zone so can determine offset. 
  camModel = ""
  timeOffset = 0
  Dir.foreach(destPhoto) do |item|
    # This is only run once, so efficiency doesn't matter
    count = 0
    next if ignoreNonFiles(item)  # skipping file when true == true
    fn = destPhoto + item
    fileEXIF = MiniExiftool.new(fn) # used several times
    camModel = fileEXIF.model
    puts "#{lineNum}. model: #{camModel} fn: #{fn}" # debug
    panasonicLocation = fileEXIF.location
    # timeOffset = 0 # could leave this in and remove the else     
    if File.file?(fn)
      if camModel  == "DMC-TS5"
        # Offset sign is same as GMT offset, eg, we are -8, but need to increase the time to match UST, therefore negative
        timeOffset = - fileEXIF.dateTimeOriginal.utc_offset # Time zone is set in camera, i.e. local time in this case
        # What does utc_offset do for the above. dateTimeOriginal is just a time, e.g., 2018:12:31 21:38:32, which is the time the camera thinks it is. Camera doesn't know about zone. Camera may, but from dateTimeOriginal, can't tell the time zone.
        puts "#{lineNum}. timeOffset: #{timeOffset} for DMC-TS5 photos stamped in local time."
      elsif camModel == "DMC-GX8"# Assumes GX8 always on local time. Made if's a bit more complex, but keeping logic simpler
        timeOffset = tzoLoc * 3600
        puts "#{lineNum}. timeOffset: #{timeOffset} seconds with GX-8 photos stamped in local time. tzoLoc: #{tzoLoc}"
      elsif camModel.include?("DMC") and panasonicLocation.length > 0 # Panasonic in Travel Mode, but also some photos exported from Photos. 
        timeOffset = tzoLoc * 3600
        puts "#{lineNum}. timeOffset: #{timeOffset} sec (#{tzoLoc} hours) with photos stamped in local time."
      else # GX7 time is UTC. iPhone ends up here too
        timeOffset = 0 # camelCase, but perl variable is lowercase
        puts "#{lineNum}. timeOffset: #{timeOffset} sec (#{tzoLoc} hours) with photos stamped in GMT"
      end # if camModel
      
      fileEXIF.save 
      count += 1
    end # if File.file
    break if count == 1 # once have a real photo file, can get out of this. Only check htis once
  end # Dir.foreach
  puts "#{lineNum}. timeOffset: #{timeOffset}. camModel: #{camModel}. All photos must be same camera and time zone or photos may be mislabeled and geo-located."
   
  puts "\n#{lineNum}. Finding all gps points from all the gpx files using gpsPhoto.pl. This may take a while. \n"
  # Since have to manually craft the perl call, need one for with Daguerre and one for on laptop
  # Daguerre version. /Volumes/Daguerre/_Download folder/Latest Download/
  
  perlOutput = `perl '#{gpsPhotoPerl}' --dir '#{destPhoto}' --gpsdir '#{folderGPX}' --timeoffset #{timeOffset} --maxtimediff 50000`
  # The following is identical, so apparently was taken care of elsewhere. So now use the single line above
    # if loadingToLaptop
    #   # perlOutput = `perl '/Users/gscar/Documents/Ruby/Photo\ handling/lib/gpsPhoto.pl' --dir '/Users/gscar/Pictures/_Photo Processing Folders/Processed\ photos\ to\ be\ imported\ to\ Aperture/' --gpsdir '/Users/gscar/Dropbox/\ GPX\ daily\ logs/2017\ Massaged/' --timeoffset #{timeOffset} --maxtimediff 50000` # saved in case something goes wrong. This works
    #   perlOutput = `perl '#{gpsPhotoPerl}' --dir '#{destPhoto}' --gpsdir '#{folderGPX}' --timeoffset #{timeOffset} --maxtimediff 50000`
    # else # default location on Daguerre or Knobby Aperture Two
    #   # perlOutput = `perl '/Users/gscar/Documents/Ruby/Photo\ handling/lib/gpsPhoto.pl' --dir '/Volumes/Knobby Aperture Two/_Download\ folder/Latest\ Download/' --gpsdir '/Users/gscar/Dropbox/\ GPX\ daily\ logs/2017\ Massaged/' --timeoffset #{timeOffset} --maxtimediff 50000` # this works, saving in case the following doesn't
    #   perlOutput = `perl '#{gpsPhotoPerl}' --dir '#{destPhoto}' --gpsdir '#{folderGPX}' --timeoffset #{timeOffset} --maxtimediff 50000`
    #   # Double quotes needed for variables to be evalated
    #   # perlOutput = "`perl \'#{gpsPhotoPerl.shellescape}\' --dir \'#{destPhoto.shellescape}\' --gpsdir \'#{folderGPX.shellescape}\' --timeoffset #{timeOffset} --maxtimediff 50000`" #  2>&1
    #   # perlOutput = "`perl '/Users/gscar/Documents/Ruby/Photo\ handling/lib/gpsPhoto.pl' --dir '/Volumes/Knobby Aperture Two/_Download\ folder/Latest\ Download/' --gpsdir '/Users/gscar/Dropbox/\ GPX\ daily\ logs/2017\ Massaged/' --timeoffset #{timeOffset} --maxtimediff 50000 2>&1` " #  2>&1 is needed to capture output, but not to run
    #
    #   puts "#{lineNum}. perlOutput: #{perlOutput}"
    # end
      
  # puts "\n374.. perlOutput: \n#{perlOutput} \n\nEnd of perlOutput ================… end 374\n\n" # This didn't seem to be happening with 2>&1 appended? But w/o it, error not captured
  # perlOutput =~ /timediff\=([0-9]+)/
  # timediff = $1 # class string
  # # puts"\n #{lineNum} timediff: #{timediff}. timediff.class: #{timediff.class}. "
  # if timediff.to_i > 240
  #   timeDiffReport = ". Note that timediff is #{timediff} seconds. "
  #   # writing to the photo file about high timediff
  #   writeTimeDiff(imageFile,timediff)
  # else
  #   timeDiffReport = ""
  # end # timediff.to…
  return perlOutput
end # addCoordinates

# Distance between two gps points. Used to reuse location information for nearby photos.
def distanceMeters(lat1, lon1, lat2, lon2)
  # https://stackoverflow.com/questions/12966638/how-to-calculate-the-distance-between-two-gps-coordinates-without-using-google-m
  lat1_rad, lat2_rad = lat1 * RAD_PER_DEG, lat2 * RAD_PER_DEG
  lon1_rad, lon2_rad = lon1 * RAD_PER_DEG, lon2 * RAD_PER_DEG

  a = Math.sin((lat2_rad - lat1_rad) / 2) ** 2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin((lon2_rad - lon1_rad) / 2) ** 2
  c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1 - a))

  RM * c # Delta in meters  
end

def addLocation(src, geoNamesUser)
  # read coords and add a hierarchy of choices for location information. Look at GPS Log Renaming for what works.
    countTotal = 0 
    countLoc = 0
    latPrev = 0.0
    lonPrev = 0.0
    countryCode = country = state = city = location = ""
    Dir.foreach(src) do |item| 
      next if ignoreNonFiles(item) == true # skipping file when true
      fn = src + item
      if File.file?(fn) 
        countTotal += 1
        # puts "\n#{lineNum}. #{countTotal}. #{item}. Adding location information using geonames based on coordinates. " # amounts to a progress bar, even if a bit verbose #{timeStamp(timeNowWas)}
        print "." # Minimal progress bar
        fileEXIF = MiniExiftool.new(fn)
        # Get lat and lon from photo file. What is this fileEXIF.specialinstructions. This must be written by the perl script.
        puts "#{lineNum}. No gps information for #{item}. #{fileEXIF.title}. fileEXIF.specialinstructions: #{fileEXIF.specialinstructions}" if fileEXIF.specialinstructions == nil
        next if fileEXIF.specialinstructions == nil # can I combine this step and the one above into one step or if statement? I think I'm writing GPS coords to this field because easier to parse? I think the perl script does it. I can't find where I did it.
        # puts "#{lineNum}. fileEXIF.specialinstructions: #{fileEXIF.specialinstructions}"
        gps = fileEXIF.specialinstructions.split(", ") # or some way of getting lat and lon. This is a good start. Look at input form needed
        lat = (gps[0][4,11]).to_f # Capture long numbers like -123.123456, but short ones aren't that long, but nothing is there
        lon = (gps[1][4,11].split(" ")[0]).to_f # needs to 11 long to capture when -xxx.xxxxxx, but then can capture the - when it's xx.xxxxxx. Then grab whats between the first two spaces. Still need the 4,11 because there seems to be a space at the beginning if leave out [4,11]
        # puts " #{lineNum}. #{lat} #{lon} for #{fn}" # put here because of fail with TS5 file with erroneous lat lon
        # puts " #{lineNum}. #{lat.to_i} #{lon.to_i} for #{fn}" # put here because of fail with TS5 file with erroneous lat lon        
        # Quick and dirty to block erroneous TS5 results, but need to fix coordinates earlier.
        if lat.to_i > 180 
          puts "#{lineNum}. #{fn} is a TS5 photo with erroneous GPS data, but the script needs to be fixed to add data"
        end
        next if lat.to_i > 180 # takes care of erroneous GPS coords in TS5 photos, but need to fix
        countLoc += 1 # gives an error here or at the end.
        # puts "#{lineNum}..#{countTotal}. Use geonames to determine city, state, country, and location for #{item}"
        api = GeoNames.new(username: geoNamesUser)
        # puts "#{lineNum}..#{countTotal}... geoNamesUser: #{geoNamesUser}. api: #{api}"

        # Reusing info for nearby points
        # puts "#{lineNum}. latPrev: #{latPrev}. latPrev.class: #{latPrev.class}. lat: #{lat}.  lat.class: #{lat.class}" # debug
       distanceMeters = distanceMeters(lat, lon, latPrev, lonPrev)
       if distanceMeters > 100.0 # distance between reference lat lon is greater than 100m recalculate location, otherwise use         # Determine country 
          begin
            # doesn't work for Istanbul, works for Croatia, Canada
            countryCodeGeo = api.country_code(lat: lat, lng: lon) # doesn't work in Turkey
           puts "\n#{lineNum}.. countryCodeGeo: #{countryCodeGeo}" # debug
            countryCode  = countryCodeGeo['countryCode']
            puts "#{lineNum}.. countryCode #{countryCode}." # DEBUG
          rescue
            # begin
             $stderr.print
             puts "#{lineNum}. $stderr: #{$stderr} for api.country_code (lat: #{lat}, lng: #{lon}) or countryCode  = countryCodeGeo['countryCode']: #{countryCode}. for #{item}"
             # Was trying to capture the message, but now failing even when not exceeded hourly limit, so comment out
             # if message.include?("the hourly limit")
             #   puts "#{lineNum}. #{e.message}, so we will wait an hour"
             #   sleep(1.hour)
             # else
               countryCodeGeo = api.find_nearby_place_name(lat: lat, lng: lon).first # works for Turkey
               #          $stderr.print  $! # Thomas p. 108
             # end
          end # rescue
       
        # puts "#{lineNum}.. countryCode:  #{countryCode}"
        # puts "#{lineNum}. NEED TO UNCOMMENT THIS AFTER INDONESIA ##############################################"
        country = countryCodeGeo['countryName'] # works with both country_code  and find_nearby_place_name above
        # puts "#{lineNum}.. country:      #{country}"

        # Determine city, state, location
        if countryCode == "US" # geocodio works in US and Canada, could use as an option to geocode.org
          begin # state
            postalCodes = api.find_nearby_postal_codes(lat: lat, lng: lon, maxRows: 1) # this comes up blank for some locations in the US eg P1230119, so did find_nearest_address 
            state = postalCodes.first['adminName1']
            # puts "#{lineNum}.. api.find_nearby_postal_codes worked"
          rescue 
            state = api.country_subdivision(lat: lat, lng: lon, maxRows: 1)['adminName1']
            # puts "#{lineNum}. api.find_nearby_postal_codes failed, so used  api.country_subdivision"
          end # if country code
          # puts "#{lineNum}.. state:        #{state}"
        
          begin  # city, location
            neigh = api.neighbourhood(lat: lat, lng: lon) # errors outside the US and at other time
            city =  neigh['city']
            # puts "#{lineNum}.. city:         #{city}"
            location = neigh['name']
            # puts "386.. location:     #{location}"
          rescue # could use api.find_nearby_postal_codes for some of this
            # puts "344.  api.neighbourhood failed for #{lat} #{lon}"
          
            begin # within a rescue
              city = postalCodes.first['placeName'] # breaking for some points, but is it better than replacement? If so add another rescue
              # puts "#{lineNum}.. city (rescue): #{city}"
              findNearbyPlaceName = api.find_nearby_place_name(lat: lat, lng: lon)
              location = findNearbyPlaceName.first['toponymName']
              # puts "#{lineNum}.. location (rescue): #{location}"      
            rescue # probably end up here for a remote place, so wikipedia may be the best
              # puts "#{lineNum}.. find_nearby_postal_codes failed for city, so use Wikipedia to find a location"
              city = ""
              distance = api.find_nearby_wikipedia(lat: lat, lng: lon, maxRows: 1)['geonames'].first['distance']
              location = api.find_nearby_wikipedia(lat: lat, lng: lon, maxRows: 1)['geonames'].first['title']
              puts "#{lineNum}.. location:     #{location}. distance: #{distance}" # may need to screen as for outside US
            end # of within a rescue
          end # begin rescue outer
        
        else # outside US. Doesn't work in Indonesia
        
          # Uncomment below for Indonesia. Could probably generalize this for other countries. But it requires downloading the file to pgAdmin and building a database.
          # locationIN  = indoLocation(lat,lon)
   #        countryCode  = locationIN[0]
   #        city         = locationIN[1]
   #        location     = locationIN[2]
   #        if countryCode == "ID"
   #          country = "Indonesia"
   #        else
   #          country = ""
   #        end
                 
          # off for Indonesia and Ethiopia, just skip if         
          begin
            findNearbyPostalCodes = api.find_nearby_postal_codes(lat: lat, lng: lon, maxRows: 1).first
            state = findNearbyPostalCodes['adminName1']
            # puts "#{lineNum}.. state (outside US): #{state}" # DEBUG
            city = findNearbyPostalCodes['placeName'] # close to city, but misses Dubrovnik and Zagreb
            # Below was normal I think, but turned off to try to get Canada to work
            city = api.find_nearby_place_name(lat: lat, lng: lon, maxRows: 1).first['toponymName'] # name or adminName1 could work too
            # puts "#{lineNum}.. city (outside US):  #{city}" # DEBUG
          rescue
            # puts "#{lineNum}. findNearbyPostalCodes failed, therefore try getting location from Wikipedia" # This can work outside the US, maybe fails when not near a city.  # DEBUG
          end
        
          # puts city =  api.find_nearby_wikipedia(lat: lat, lng: lon)["geonames"].first["title"] # the third item is a city, maybe could regex wikipedia, but doubt it's consistent enough to work
          # puts "#{lineNum}.. Four lines below must be commented out for Canada"
        
          begin # put this in with failure anotating Ethiopia photos
            location = api.find_nearby_wikipedia(lat: lat, lng: lon, maxRows: 1)['geonames'].first['title']
            distance = api.find_nearby_wikipedia(lat: lat, lng: lon, maxRows: 1)['geonames'].first['distance'].to_f
            locationDistance = "#{location} is #{distance}km away."
            puts "#{lineNum}. location:     #{location}. distance: #{distance}. If distance > 0.3km location not used"
            if  distance < 0.3
              location = ""
            elsif fileEXIF.caption == nil
              fileEXIF.caption = locationDistance
            else
              fileEXIF.usercomment = locationDistance
            end # if distance
          rescue
            # maybe this whole exception needs reworking
          ensure
            # puts "#{lineNum}. #{item} find api.find_nearby_wikipedia failed. Maybe a foreign country? " # DEBUG
            location = "" # added this to help prevent failure on test below. May not be necessary
          end
        end # if countryCode
        location = "" if city == location # cases where they where the same (Myers Flat, Callahan and Etna). Could try to find a location with some other find, maybe Wikipedia, but would want a distance check
        latPrev  = lat
        lonPrev = lon
      # else # commented out since not usng, but can for debug
        # puts "#{lineNum}. #{distanceMeters.ceil}m between the current and previous photo and since less than 100m will use the location information from the previous photo." # Debug
      end # if > 100m (so if greater recalculated above, other wise just reuse below)  
      
      # puts "#{lineNum}.. Use MiniExiftool to write location info to photo files\n" # Have already set fileEXIF
      fileEXIF.CountryCode = countryCode
      fileEXIF.country     = country
      fileEXIF.state       = state
      fileEXIF.city        = city
      fileEXIF.location    = location
      fileEXIF.save
    end    
  end 
  puts "\n#{lineNum}. Location information found for #{countLoc} of #{countTotal} photos processed" 
end # addLocation

def indoLocation(lat,lon) # Could modify for other countries. Uses file loaded into PGadmin
  conn = PG.connect( dbname: 'Indonesia' )
  #  lon/lat is the order for ST_GeomFromText
  indo  = conn.exec("SELECT * FROM indonesia ORDER BY ST_Distance(ST_GeomFromText('POINT(#{lon} #{lat})', 4326), geom) ASC LIMIT 1")
  country = indo.getvalue(0,8)
  name    = indo.getvalue(0,1)
  altNames= indo.getvalue(0,3)
  # puts "\#{lineNum}. Indonesia country: #{country}"
  # puts "#{lineNum}. Indonesia name: #{name}"
  # puts "#{lineNum}. Indonesia alt names: #{altNames}"
  result = [country, name, altNames]
  # puts "\#{lineNum} result #{result}"
end

def writeTimeDiff(perlOutput)
  perlOutput.each_line do |line|
    if line =~ /timediff=/
      fn = $`.split(",")[0]
      timeDiff = $'.split(" ")[0]
      # puts "\n515.. #{fn} timeDiff: #{timeDiff}"
      fileEXIF = MiniExiftool.new(fn)
      fileEXIF.usageterms = "#{sprintf '%.0f', timeDiff} seconds from nearest GPS point"
      fileEXIF.save
    end
  end
end #  Write timeDiff to the photo files

def file_prepend(file, str)
  # For adding the last photo processed to beginning of file.
  # https://stackoverflow.com/questions/8623231/prepend-a-single-line-to-file-with-ruby Copied
  new_contents = ""
  str = str + "\n" # not in original, but needed to put this return in somewhere
  File.open(file, 'r') do |fd|
    contents = fd.read
    new_contents = str << contents
  end
  # Overwrite file but now with prepended string on it
  File.open(file, 'w') do |fd| 
    fd.write(new_contents)
  end
end

def moveToMylio(destPhoto, mylioFolder)
  puts "\n#{lineNum}. Moving processed photos from #{destPhoto} to Mylio folder #{mylioFolder}"
  Dir.foreach(destPhoto) do |item|
    fn  = destPhoto + item # destPhoto is now temporary destination, so nomenclature is weird
    fnp = mylioFolder + item
    # puts "#{lineNum}.#{jpgsMovedCount += 1}. #{fn} moved to #{fnp}" # dubugging
    next if ignoreNonFiles(item) == true # skipping file when true
    FileUtils.move(fn, fnp)
  end
  puts "Photos moved to Mylio folder, #{mylioFolder}, where they will automagically be imported into Mylio"
end

## The "PROGRAM" ############ ##################### ###################### ##################### ##########################
timeNowWas = timeStamp(Time.now, lineNum) # Initializing. Later calls are different
# timeNowWas = timeStamp(timeNowWas)
puts "Are the gps logs up to date?" # Should check for this since I don't see the message
puts "Fine naming and moving started  . . . . . . . . . . . . " # for trial runs  #{timeNowWas}

# Two names for SD cards seem common
unless File.directory?(srcSDfolder) # negative if, so if srcSDfolder exists skip, other wise change reference to …Alt
  srcSDfolder = srcSDfolderAlt
  sdCard      = sdCardAlt
end

# need to determine this based on last file and that will have to be later Which has been done so commented out 2019.07.20
# srcSD = srcSDfolder + sdFolder(sdFolderFile)

# if Daguerre isn't mounted use folders on laptop. 
if File.exists?(downloadsFolders)
  puts "#{lineNum}. Using Daguerre. File.exists?(downloadsFolders (#{downloadsFolders})): #{File.exists?(downloadsFolders)}"
else
   puts "\n#{lineNum}. #{downloadsFolders} isn't mounted, so will use local laptop folders to process"
  # Daguerre folders location loaded by default, changed as needed
  downloadsFolders = laptopDownloadsFolder # line ~844
  destPhoto        = laptopDestination
  destOrig         = laptopDestOrig
  tempJpg          = laptopTempJpg
  srcHD            = downloadsFolders # is this being used?
  # loadingToLaptop = true # No longer used
end

# Check if photos are already in Latest Download folder. A problem because they get reprocessed by gps coordinate adding.
folderPhotoCount = Dir.entries(destPhoto).count - 3 # -3 is a crude way to take care of ., .., .. Crude is probably OK since this isn't critical. If one real photo is there, not a big problem
if folderPhotoCount > 0
  puts "#{lineNum}. downloadsFolders: #{downloadsFolders}. Check if Pashua warning window appears"
  # downloadsFolderEmpty(destPhoto, folderPhotoCount) # Pashua window
else
  puts "\n#{lineNum}. 'Processed photos to be imported to Mylio/' folder is empty and script will continue."
end

# Ask whether working with photo files from SD card or HD
# fromWhere are the photos?
fromWhere = whichLoc() # This is pulling in first Pashua window (1. ), SDorHD.rb which has been required # 
# puts "#{lineNum}. fromWhere: #{fromWhere}" #{"rename"=>"1", "whichDrive"=>"SD card to be selected in the next window", "gpsLocation"=>"0", "gpsCoords"=>"0", "cb"=>"0"}
# puts "\n#{lineNum}. fromWhere[\"rename\"]: #{fromWhere["rename"]}"
# puts "#{lineNum}. fromWhere[\"gpsCoords\"]: #{fromWhere["gpsCoords"]}"
# puts "#{lineNum}. fromWhere[\"gpsLocation\"]: #{fromWhere["gpsLocation"]}"
whichDrive = fromWhere["whichDrive"][0].chr # only using the first character
# A: already downloaded. S: SD card. 
# puts "\n#{lineNum}.. whichDrive: #{whichDrive}. (A: already downloaded. S: SD card.)" #\nWill convert to SD or HD
# Set the return into a more friendly variable and set the src of the photos to be processed
whichOne = whichOne(whichDrive) # parsing result to get HD or SD
# puts "#{lineNum}. fromWherefromWhere: #{fromWhere}. whichDrive: #{whichDrive}. whichOne: #{whichOne}" # fromWhere not defined
# Only rename files in place and skip the rest. Not sure right location because not sure about when Pashua is run
# puts "#{lineNum}. whichOne: #{whichOne}" # debug
# # puts whichLoc()

# Getting the folder selected in the dialog box, but also sending the default

# Three options for partial processing, then go to either HD or SD
# Option for renaming files while not moving photos
# Now the logic is a mess, since for the three options below we stop and don't do any of the rest
if fromWhere["rename"] == "1" # Renaming only or could use if whichOne == "Rename"
  renameFolder = renameGUI(srcRename) 
  srcRename = renameFolder["srcSelect"].to_s  + "/" # Name in dialog box which may be different than default
  puts "\n#{lineNum}. Photos in #{srcRename} will be renamed using date and time."
  rename(srcRename, timeZonesFile, timeNowWas)
  # abort # break gives compile error
  abort if (whichDrive == "R") # break doesn't work, but abort seems to
end

# Option for adding GPS coordinates while not moving photos
if fromWhere["gpsCoords"] == "1" # Renaming only or could use if whichOne == "Rename"
  srcGpsAdd = gpsCoordsGUI(srcGpsAdd) # Puts up dialog box, sends default file location and retrieves selected file location
  srcGpsAdd = srcGpsAdd["srcSelect"].to_s  + "/" # Name in dialog box which may be different than default
  puts "\n#{lineNum}. NOT WORKING YET. Photos in #{srcGpsAdd} will have GPS coordinates added in place."
  puts "PAY ATTENTION TO YEAR AS NOT SURE MORE THAN ONE YEAR IS INCLUDED IN MY MODULE"
  puts "#{lineNum} Debugging.\n srcGpsAdd: #{srcGpsAdd} \n folderGPX: #{folderGPX}  \n gpsPhotoPerl: #{gpsPhotoPerl}  \n tzoLoc: #{tzoLoc} added manually. TODO ask for"
  perlOutput = addCoordinates(srcGpsAdd, folderGPX, gpsPhotoPerl, tzoLoc) # Don't need perlOutput since abort
  puts "#{lineNum}. Added coordinates to photos in #{srcGpsAdd}\nMultiline perlOutput follows:\n#{perlOutput}"
  abort # break gives compile error
  # abort if (whichDrive == "R") # break doesn't work, but abort seems to
end

# Option for adding location information based on GPS coordinates while not moving photos
if fromWhere["gpsLocation"] == "1"
  srcAddLocation = addLocationGUI(srcAddLocation)  # Puts up dialog box, sends default file location and retrieves selected file location. reusing variable. One above made new temporary variable
  srcAddLocation = srcAddLocation["srcSelect"].to_s  + "/" # Name in dialog box which may be different than default
  puts "\n#{lineNum}. NOT IMPLEMENTED. Photos in #{srcAddLocation} will have location information added based on GPS coordinates in EXIF data without moving the file. NOT IMPLEMENTED."
  puts "#{lineNum}. Need to confirm that the following works. May need to change year of folder for gpx tracks"
  addLocation(srcAddLocation, geoNamesUser)
  abort # break gives compile error
  # abort if (whichDrive == "R") # break doesn't work, but abort seems to
end

lastPhotoReadTextFile = sdCard + "/lastPhotoRead.txt"
# if File.exist?(lastPhotoReadTextFile) # If SD card not mounted. TODO logic with else to try again

if whichOne=="SD" # otherwise it's HD, probably should be case for cleaner coding
  # if File.exist?(lastPhotoReadTextFile) # If SD card not mounted. TODO logic with else to try again
  # TODO Put up a dialog to remind to mount the SD card and return to here.
  # read in last filename copied from card previously
  begin
    # Read from SD card
    # lastPhotoReadTextFile = sdCard + "/lastPhotoRead.txt" # But this doesn't work if a new card.
    puts "\n#{lineNum}. lastPhotoReadTextFile: #{lastPhotoReadTextFile}. NEED an error here if card not mounted!!. Have a kludge fix in the next rescue."
    file = File.new(lastPhotoReadTextFile, "r")
    lastPhotoFilename = file.gets # apparently grabbing a return. maybe not the best reading method.
    puts "\n#{lineNum}. lastPhotoFilename: #{lastPhotoFilename.chop}. Value can be changed by user, so this may not be the value used."
    # lastPhotoFilename is 8 characters long (P plus 7 digits) at present.
    # Adding date to this line, so will take first 12 characters (would be cleaner if made the write an array or json and worked with that, but this is the quick and dirty)
    lastPhotoFilename = lastPhotoFilename[0..7]
    puts "#{lineNum}. lastPhotoFilename: #{lastPhotoFilename}. Confirming new method of reading. Should look like line above. Not implemented as haven't found an easy way to write to the beginning of the file."
    file.close
  # rescue Exception => err # Not good to rescue Exception
  rescue => err
    puts "Exception: #{err}. Not critical as value can be entered manually by user.\n"
  end

  begin
    srcSD = srcSDfolder + lastPhotoFilename.chop.slice(1,3) + "_PANA"
  rescue Exception => e
    puts "#{lineNum} +++++++++++++ SD card not available, so will EXIT.++++++++++. Probably selected wrong option."
    exit
  end

# Don't know if this is needed, why not use srcSD directly
  src = srcSD
  prefsPhoto = pPashua2(src,lastPhotoFilename,destPhoto,destOrig) # calling Photo_Handling_Pashua-SD. (Titled: 2. SD card photo downloading options)
  # to get a value use prefsPhoto("theNameInFileNamingEtcPashua.rb"), nothing to do with the name above
  # puts "Prefs as set by pPashua"
  # prefsPhoto.each {|key,value| puts "#{key}:       #{value}"}
else # whichOne=="HD", but what
  src = srcHD
  # puts "#{lineNum}. `srcHD`: #{src}. Does it have a slash?"
  prefsPhoto = pGUI(src, destPhoto, destOrig) # is this only sending values in? 
  # to get a value use prefsPhoto("theNameInFileNamingEtcPashue.rb"), nothing to do with the name above
  # puts "Prefs as set by pGUI"
  # prefsPhoto.each {|key,value| puts "#{key}:       #{value}"}
  src = prefsPhoto["srcSelect"].to_s  + "/"
  # puts "#{lineNum}. src: #{src}. Does it have a slash?"
end # whichOne=="SD"
# else
#   puts "#{lineNum}. SD card not mounted. (=== Some logic so can mount and try again. ===)"
#   abort
# end #SD card mounted

destPhoto = prefsPhoto["destPhotoP"].to_s + "/" 
destOrig  = prefsPhoto["destOrig"].to_s + "/"
# Above are true whether SD or from another folder

# But first check that destPhoto is empty. I'm assuming destPhoto has been determined at this point
destPhotoCount = Dir.entries(destPhoto).count
if destPhotoCount > 3 # 
  puts "\n#{lineNum}. #{destPhotoCount} files are in the destination folder"
  # Put up a notice or ask if want to delete them. Or list the first few
end

puts "\n#{lineNum}. Initialization complete. File renaming and copying/moving beginning.\n        Time below is responding to options requests via Pashua if copying an SD card, otherwise the two times will be the same."

timeNowWas = timeStamp(timeNowWas, lineNum)

#  If working from SD card, copy or move files to " Drag Photos HERE Drag Photos HERE" folder, then will process from there.
# puts "#{lineNum}..   src: #{src} \nsrcHD: #{srcHD}"

copySD(src, srcHD, srcSDfolder, lastPhotoFilename, lastPhotoReadTextFile, thisScript) if whichOne == "SD"
#  Note that file creation date is the time of copying. May want to fix this. Maybe a mv is a copy and move which is sort of a recreation. 

timeNowWas = timeStamp(timeNowWas, lineNum)

puts "\n#{lineNum}. Photos will now be copied and moved in readiness for renaming, etc."

# COPY AND MOVE and sort jpgs
# Which drive has already been decided. (this note because it hadn't yet if Daguerre wasn't available)
photosArray = copyAndMove(srcHD, destPhoto, tempJpg, destOrig, photosArray)
# Now do the same for the jpg files. Going to tempJpg and moving files to same places, except no jpg's will move to tempJpg

# photosArray = copyAndMove(tempJpg, destPhoto, tempJpg, destOrig, photosArray)
# puts "#{lineNum}. photosArray:" # Arrays seem to get mixed up if put in a {}
# puts photosArray
#  To see how it looks
puts "\n#{lineNum}. photosArray[2]: #{photosArray[2]}. Sample of photosArray. NEEDS to have dateTimeStamp if to be useful, which it doesn't now." # Shows everything
# puts "photosArray[2]: " + photosArray[2] # only the index (3) shows up, not now
puts "#{lineNum}. Next should write photosArray to #{photoArrayFile}"
File.write(photoArrayFile, photosArray) # A list of all the files processed. Saved with script. Work with this later
# unmount card. Test if using the SD
# puts "\n#{lineNum}. fromWhere: #{fromWhere}. whichDrive: #{whichDrive}. whichOne: #{whichOne}"
# whichOne =="SD" ? unmountCard(sdCard) : "" # not working so turned off TODO

# timeNowWas = timeStamp(timeNowWas, lineNum) # moved into line below

puts "\n#{lineNum}. Photos will now be renamed. #{timeNowWas = timeStamp(timeNowWas, lineNum)}"

puts "\n#{lineNum}. Rename [tzoLoc = rename(…)] the photo files with date and an ID for the camera or photographer (except for the paired jpgs in #{tempJpg}). #{timeNowWas}\n"
# tzoLoc = timeZone(fileDateTimeOriginal, timeZonesFile) # Second time this variable name is used, other is in a method
# RENAME Raw
tzoLoc = - rename(destPhoto, timeZonesFile , timeNowWas).to_i # This also calls rename which processes the photos, but need tzoLoc value. Negative because need to subtract offset to get GMT time. E.g., 10 am PST (-8)  is 18 GMT

timeNowWas = timeStamp(timeNowWas, lineNum)
#Rename the jpgs and then move to Latest Download
puts "\n#{lineNum}. Rename the jpgs in #{tempJpg} and then move to #{destPhoto}. #{timeNowWas = timeStamp(timeNowWas, lineNum)}"
rename(tempJpg, timeZonesFile, timeNowWas)
#  Move the jpgs to destPhoto (Latest Download)
jpgsMovedCount = 0 # Initializing for debugging puts
Dir.foreach(tempJpg) do |item|
  next if ignoreNonFiles(item) == true
  fn  = tempJpg   + item # sourced from temporary storage for jpgs 
  fnp = destPhoto + item # new jpg file in Latest Download
  # puts "#{lineNum}.#{jpgsMovedCount += 1}. #{fn} moved to #{fnp}" # dubugging
  FileUtils.move(fn, fnp)
end

puts "\n#{lineNum} tzoLoc: #{tzoLoc}. Because GX8 and some other cameras use local time and not GMT as this script was originally written for. All photos must be in same time zone."
timeNowWas = timeStamp(timeNowWas, lineNum)

puts "\n#{lineNum}. Using perl script to add gps coordinates. Will take a while as all the gps files for the year will be processed and then all the photos. -tzoLoc, `i.e.: GMT #{-tzoLoc}"

# Add GPS coordinates. Will add location later using some options depending on which country since different databases are relevant.
perlOutput = addCoordinates(destPhoto, folderGPX, gpsPhotoPerl, tzoLoc)

timeNowWas = timeStamp(timeNowWas, lineNum)

# Write timeDiff to the photo files
puts "\n#{lineNum}. Write timeDiff to the photo files"
writeTimeDiff(perlOutput)

timeNowWas = timeStamp(timeNowWas, lineNum)
# Parce perlOutput and add maxTimeDiff info to photo files

puts "\n#{lineNum}. All Finished. Note that \"Adding location information to photo files\" is commented out."

# puts "\n#{lineNum}. Adding location information to photo files"
# # Add location information to photo file
# addLocation(destPhoto, geoNamesUser)

# Move to Mylio folder (can't process in this folder or Mylio might import before changes are made)
mylioFolder = iMacMylio # need to generalize this
moveToMylio(destPhoto, mylioFolder)

# timeNowWas = timeStamp(timeNowWas, lineNum)
# puts "\n#{lineNum}.-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  - All done"
