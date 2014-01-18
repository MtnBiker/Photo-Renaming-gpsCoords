require 'mini_exiftool' # Requires Ruby ≥1.9. A wrapper for the Perl ExifTool
require 'fileutils'
include FileUtils
require 'find'
require 'geonames'
geoNamesUser    = "geonames@web.knobby.ws"


fn = "/Volumes/Knobby Aperture II/_Download folder/Latest Download/2013.09.14-20.42.44.gs.L.rw2" # Croatia
fn = "/Volumes/Knobby Aperture II/_Download folder/Latest Download/2014.01.15-11.12.42.gs.L 9.47.30 PM.rw2" # Home


fileEXIF = MiniExiftool.new(fn)

# Special Instructions            : Lat 33.812123, Lon -118.383647 - Bearing: unknown - Altitude: 29m. Individual lat and long are in deg min sec
# "Lat 42.643018", "Lon 18.107581 - Bearing: unknown - Altitude: 49m"]
if fileEXIF.specialinstructions != nil
 gps = fileEXIF.specialinstructions.split(", ") # or some way of getting lat and lon. This is a good start. Look at input form needed
 puts "gps: #{gps}. gps.class: #{gps.class}"
else
  puts "No gps information for #{fn}" # better if item
end
lat = gps[0][4,11] # Capture long numbers like -123.123456, but short ones aren't that long, but nothing is there
puts gps[1]
lon = gps[1][4,11].split(" ")[0] # needs to 11 long to capture when -xxx.xxxxxx, but then can capture the - when it's xx.xxxxxx. Then grab whats between the first two spaces. Still need the 4,11 because there seems to be a space at the beginning if leave out [4,11]

puts "lat:  #{lat}"
puts "lon: #{lon}"
# 
# #  neighborhood and find_nearby fails for this
# lat =   33.836603
# lon = -118.377645

# Center of Dubrovnik
# lon = 18.0913889
# lat = 42.6505556


api = GeoNames.new(username: geoNamesUser) # required with Jan 2014 version
puts "\ncountryCode = api.country_code(lat: lat, lng: lon):\n  #{countryCode = api.country_code(lat: lat, lng: lon)}." # setting distance to 0.5 [radius: 0.5] still got info at 1.3km
# not sure sigPlace and distance are needed; may be too much noise

begin
  puts "\nsigPlace = api.find_nearby_wikipedia(lat: lat, lng: lon)[\"geonames\"].first[\"title\"]\n  #{sigPlace = api.find_nearby_wikipedia(lat: lat, lng: lon)["geonames"].first["title"]}."
  puts distance = api.find_nearby_wikipedia(lat: lat, lng: lon)["geonames"].first["distance"] 
rescue
  puts "No find_nearby_wikipedia for this location"
end
puts
begin
  puts find_nearest_address = api.find_nearest_address(lat: lat, lng: lon)["address"]
rescue
  puts "find_nearest_address failed"
end
# nearbyToponymName = api.find_nearby(lat: lat, lng: lon).first["toponymName"]

begin
  neigh = api.neighbourhood(lat: lat, lng: lon) # errors outside the US and at other time
  puts "55. api.neighbourhood #{sigPlace} (#{distance[0..3]}km), #{neigh['name']}, #{neigh['city']}, #{neigh['adminName2']}, #{neigh['adminCode1']}" 
rescue
  # maybe put the other option here or a flag
  puts "61. no neighborhood information for #{fn}"
end

begin
  puts "40. #{sigPlace} (#{distance[0..3]}km), #{nearbyToponymName}, #{find_nearest_address["placename"]}, #{find_nearest_address["adminName2"]} County, #{find_nearest_address["adminName1"]}, #{countryCode['countryName']}" # find_nearest_address["countryCode"] could be used but only is the code, e.g. US, instead of spelled out  
rescue
  puts "something doesn't work for this example either"
end

#####################This doesn't work
# def showResults(name,api,lat,lon)
#   puts api
#   input = api + "."+ name + "(lat: " + lat + " lng: " + lon + ")"
#   puts input
#   puts "api#{name}: #{input}"
# end
# showResults("findnearby",api,lat,lon)


# Now looking for Location, City, State, Country, and Country Code ? All but location look easy here.
#  Need to try for a foreign photo
# =============NOTES FROM GEONAME.RB
# The ISO country code of any given point.
#   #
#   # Parameters: lat, lng, type, lang, and radius (buffer in km for closest
#   # country in coastal areas)
#   #
# api.country_code(lat: 47.03, lng: 10.2)
#   def country_code
puts "\napi.country_code #{lat} #{lon}: #{api.country_code(lat: lat, lng: lon)}"

# api.country_code 33.812123 -118.383647: {"languages"=>"en-US,es-US,haw,fr", "distance"=>"0", "countryName"=>"United States", "countryCode"=>"US"}

# api.country_code 42.643018 18.107581: {"languages"=>"hr-HR,sr", "distance"=>"0", "countryName"=>"Croatia", "countryCode"=>"HR"}

#######################
# Country Subdivision / reverse geocoding
# The ISO country code and the administrative subdivision (state, province, ...) of any given point.
#
# Parameters: lat, lng, lang, radius
#
#   api.country_subdivision(lat: 47.03, lng: 10.2)
#
#   # With the parameters 'radius' and 'maxRows' you get the closest subdivisions ordered by distance:
#   api.country_subdivision(lat: 47.03, lng: 10.2, maxRows: 10, radius: 40)
# def country_subdivision
puts "\napi.country_subdivision  #{lat} #{lon}: #{api.country_subdivision(lat: lat, lng: lon)}"

# api.country_subdivision  33.812123 -118.383647: {"distance"=>0, "adminCode1"=>"CA", "countryName"=>"United States", "countryCode"=>"US", "codes"=>[{"code"=>"06", "type"=>"FIPS10-4"}, {"code"=>"CA", "type"=>"ISO3166-2"}], "adminName1"=>"California"}

# api.country_subdivision  42.643018 18.107581: {"distance"=>0, "countryName"=>"Croatia", "countryCode"=>"HR"}

########################
# Neighbourhood / reverse geocoding
  # The neighbourhood for US cities. Data provided by Zillow under cc-by-sa
  # license.
  #
  # Parameters: lat,lng
  #
  # Example:
  #
  #   api.neighbourhood(lat: 40.78343, lng: -73.96625)
  # def neighbourhood

  begin
   puts "\n123. api.neighbourhood  #{lat} #{lon}: #{api.neighbourhood(lat: lat, lng: lon)}"
  rescue
   puts "125. api.neighbourhood failed for #{lat} #{lon}. Only works in US and fails for some coords in US"
  end
  
  # api.neighbourhood  33.812123 -118.383647: {"adminName2"=>"Los Angeles County", "adminCode2"=>"037", "adminCode1"=>"CA", "countryName"=>"United States", "name"=>"Hollywood Riviera", "countryCode"=>"US", "city"=>"Torrance", "adminName1"=>"California"}
  
  # GeoNames::APIError: {"message"=>"we are afraid we could not find a neighbourhood for latitude and longitude :42.643018,18.107581", "value"=>15} ## US only
  
  # GeoNames::APIError: {"message"=>"we are afraid we could not find a neighbourhood for latitude and longitude :33.836603,-118.377645", "value"=>15} ## fails for some US locations
  ############################
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
    # def timezone
    puts "\napi.timezone  #{lat} #{lon}: #{api.timezone(lat: lat, lng: lon)}"
    
    # api.timezone  33.812123 -118.383647: {"time"=>"2014-01-17 16:42", "countryName"=>"United States", "sunset"=>"2014-01-18 17:10", "rawOffset"=>-8, "dstOffset"=>-7, "countryCode"=>"US", "gmtOffset"=>-8, "lng"=>-118.383647, "sunrise"=>"2014-01-18 06:57", "timezoneId"=>"America/Los_Angeles", "lat"=>33.812123}
    
    # api.timezone  42.643018 18.107581: {"time"=>"2014-01-18 01:54", "countryName"=>"Croatia", "sunset"=>"2014-01-18 16:42", "rawOffset"=>1, "dstOffset"=>2, "countryCode"=>"HR", "gmtOffset"=>1, "lng"=>18.107581, "sunrise"=>"2014-01-18 07:13", "timezoneId"=>"Europe/Zagreb", "lat"=>42.643018}
#####################
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
  # def find_nearby
  # puts "\napi.find_nearby  #{lat} #{lon}: #{api.find_nearby(lat: lat, lng: lon)}"
  
  # api.find_nearby  33.812123 -118.383647: [{"countryId"=>"6252001", "adminCode1"=>"CA", "countryName"=>"United States", "fclName"=>"city, village,...", "countryCode"=>"US", "lng"=>"-118.38313", "fcodeName"=>"populated place", "distance"=>"0.23339", "toponymName"=>"Hollywood Riviera", "fcl"=>"P", "name"=>"Hollywood Riviera", "fcode"=>"PPL", "geonameId"=>5357553, "lat"=>"33.81418", "adminName1"=>"California", "population"=>0}]

  # api.find_nearby  42.643018 18.107581: [{"countryId"=>"3202326", "countryName"=>"Croatia", "fclName"=>"spot, building, farm", "countryCode"=>"HR", "lng"=>"18.1047", "fcodeName"=>"hotel", "distance"=>"0.28177", "toponymName"=>"Hilton Imperial Dubrovnik", "fcl"=>"S", "name"=>"Hilton Imperial Dubrovnik", "fcode"=>"HTL", "geonameId"=>6498328, "lat"=>"42.6444", "adminName1"=>"", "population"=>0}]
  
  # GeoNames::APIError: {"message"=>"ERROR: canceling statement due to statement timeout", "value"=>13}  ## Random failure? Doubt it, repeated for 33.836603 -118.377645 which is problematic with neighbourhood too
  
#######################
# extended_find_nearby Returns the most detailed information available for the lat/lng query.
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
  # def extended_find_nearby
   # puts "\napi.extended_find_nearby  #{lat} #{lon}: #{api.extended_find_nearby(lat: lat, lng: lon)}" 
   
   # NotImplementedError: XML queries haven't been implemented. # Get this error domestically and foreign but 
   # http://api.geonames.org/extendedFindNearby?lat=33.836603&lng=-118.377645&username=geonames@web.knobby.ws works
   #  Fellinger generates this return and I think he means only XML queries are supported by geonames and he's using JSON
###################
# Find nearby populated place / reverse geocoding
  # Returns the closest populated place for the lat/lng query.
  # lat, lng,
  # radius: radius in km (optional),
  # maxRows: max number of rows (default 10),
  # style: SHORT, MEDIUM, LONG, FULL (default = MEDIUM), verbosity of result
  #
  # Example:
  #
  #   api.find_nearby_place_name(lat: 47.3, lng: 9)
  # def find_nearby_place_name
  puts "\nfind_nearby_place_name  #{lat} #{lon}: #{api.find_nearby_place_name(lat: lat, lng: lon)}"
  
  # find_nearby_place_name  33.812123 -118.383647: [{"countryId"=>"6252001", "adminCode1"=>"CA", "countryName"=>"United States", "fclName"=>"city, village,...", "countryCode"=>"US", "lng"=>"-118.38313", "fcodeName"=>"populated place", "distance"=>"0.23339", "toponymName"=>"Hollywood Riviera", "fcl"=>"P", "name"=>"Hollywood Riviera", "fcode"=>"PPL", "geonameId"=>5357553, "lat"=>"33.81418", "adminName1"=>"California", "population"=>0}]
  
  # find_nearby_place_name  42.643018 18.107581: [{"countryId"=>"3202326", "adminCode1"=>"03", "countryName"=>"Croatia", "fclName"=>"city, village,...", "countryCode"=>"HR", "lng"=>"18.12167", "fcodeName"=>"section of populated place", "distance"=>"1.18715", "toponymName"=>"Ploče", "fcl"=>"P", "name"=>"Ploče", "fcode"=>"PPLX", "geonameId"=>3193148, "lat"=>"42.64056", "adminName1"=>"Dubrovačko-Neretvanska", "population"=>0}]

  
# ####################
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
  # def find_nearby_postal_codes
  puts "\nfind_nearby_postal_codes  #{lat} #{lon} .first: #{api.find_nearby_postal_codes(lat: lat, lng: lon).first}"
  postalCodes = api.find_nearby_postal_codes(lat: lat, lng: lon, maxRows: 1).first
  # puts city = postalCodes[0]['placeName'] # [0] equiv to .first
  puts "\npostalCodes: #{postalCodes}"
    puts "\npostalCodes['placeName'], maxRows 1: #{postalCodes['placeName']}"
    puts "postalCodes goes by how far to center of a place, so you may be closer to the center of a city you're not in than the center of the one you're in. AT least it works this way in Croatia"
  #  nearby towns and postal codes and distances
  # find_nearby_postal_codes  33.812123 -118.383647: [{"adminName2"=>"Los Angeles", "adminCode2"=>"037", "distance"=>"0", "adminCode1"=>"CA", "postalCode"=>"90277", "countryCode"=>"US", "lng"=>-118.383647, "placeName"=>"Redondo Beach", "lat"=>33.812123, "adminName1"=>"California"}, {"adminName2"=>"Los Angeles", "adminCode2"=>"037", "distance"=>"3.04524", "adminCode1"=>"CA", "postalCode"=>"90505", "countryCode"=>"US", "lng"=>-118.350733, "placeName"=>"Torrance", "lat"=>33.810635, "adminName1"=>"California"}, {"adminName2"=>"Los Angeles", "adminCode2"=>"037", "distance"=>"4.09737", "adminCode1"=>"CA", "postalCode"=>"90503", "countryCode"=>"US", "lng"=>-118.354236, "placeName"=>"Torrance", "lat"=>33.839709, "adminName1"=>"California"}, {"adminName2"=>"Los Angeles", "adminCode2"=>"037", "distance"=>"5.90509", "adminCode1"=>"CA", "postalCode"=>"90254", "countryCode"=>"US", "lng"=>-118.395511, "placeName"=>"Hermosa Beach", "lat"=>33.864309, "adminName1"=>"California"}, {"adminName2"=>"Los Angeles", "adminCode2"=>"037", "distance"=>"6.47079", "adminCode1"=>"CA", "postalCode"=>"90717", "countryCode"=>"US", "lng"=>-118.3171699237468, "placeName"=>"Lomita", "lat"=>33.793809727411634, "adminName1"=>"California"}]
  
  # ##############
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
  # def find_nearest_address
begin
  puts "\nfind_nearest_address  #{lat} #{lon}: #{api.find_nearest_address(lat: lat, lng: lon)}"
rescue
  puts "\nfind_nearest_address  #{lat} #{lon} failed, because outside US in every example I've tried (failure may be a blank {})"
end
  # find_nearest_address  33.812123 -118.383647: {"address"=>{"postalcode"=>"90277", "adminCode2"=>"037", "adminCode1"=>"CA", "street"=>"Pso de Las Delicias", "countryCode"=>"US", "lng"=>"-118.3834", "placename"=>"Torrance", "adminName2"=>"Los Angeles", "distance"=>"0.02", "streetNumber"=>"281", "mtfcc"=>"S1400", "lat"=>"33.8121", "adminName1"=>"California"}}
  
  # GeoNames::APIError: {"message"=>"Cannot get a connection, pool error Timeout waiting for idle object", "value"=>12} for problem coords
  
# ##########################
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
  # def find_nearby_wikipedia
puts "\nfind_nearby_wikipedia  #{lat} #{lon}, maxRows 1: #{api.find_nearby_wikipedia(lat: lat, lng: lon, maxRows: 1)['geonames']}"

# find_nearby_wikipedia  33.812123 -118.383647: {"geonames"=>[{"summary"=>"Tulita Elementary School is located in Redondo Beach, California, United States. It's one of 8 elementary schools in the Redondo Beach Unified School District. Students attend Kindergarten through 5th grade (as of 2010) and then typically go on to Parras Middle School, and then to Redondo Union High (...)", "distance"=>"1.1527", "rank"=>8, "title"=>"Tulita Elementary School", "wikipediaUrl"=>"en.wikipedia.org/wiki/Tulita_Elementary_School", "elevation"=>29, "countryCode"=>"US", "lng"=>-118.37638888888888, "feature"=>"landmark", "geoNameId"=>5403871, "lang"=>"en", "lat"=>33.82055555555556}, {"summary"=>"South High School is a public high school in Torrance, California. It is one of five high schools in the Torrance Unified School District.  (...)", "distance"=>"1.8617", "rank"=>60, "title"=>"South High School (Torrance)", "wikipediaUrl"=>"en.wikipedia.org/wiki/South_High_School_%28Torrance%29", "elevation"=>24, "countryCode"=>"US", "lng"=>-118.36352, "feature"=>"edu", "lang"=>"en", "lat"=>33.81296}, {"summary"=>"Bishop Montgomery High School (commonly referred to as \"BMHS\" or simply \"Bishop\" by students) is a Catholic high school serving twenty-five parishes in the Roman Catholic Archdiocese of Los Angeles. BMHS was founded in 1957, and staffed by the Sisters of St (...)", "distance"=>"2.9836", "rank"=>83, "title"=>"Bishop Montgomery High School", "wikipediaUrl"=>"en.wikipedia.org/wiki/Bishop_Montgomery_High_School", "elevation"=>38, "countryCode"=>"US", "lng"=>-118.37222222222222, "feature"=>"edu", "geoNameId"=>5328829, "lang"=>"en", "lat"=>33.83722222222222}, {"summary"=>"Palos Verdes Estates is a city in Los Angeles County, California, USA on the Palos Verdes Peninsula. The city was masterplanned by the noted American landscape architect and planner Frederick Law Olmsted, Jr. The population was 13,438 at the 2010 census, up from 13,340 in the 2000 census (...)", "distance"=>"3.0471", "rank"=>93, "title"=>"Palos Verdes Estates, California", "wikipediaUrl"=>"en.wikipedia.org/wiki/Palos_Verdes_Estates%2C_California", "elevation"=>285, "countryCode"=>"US", "lng"=>-118.39666666666668, "feature"=>"city", "thumbnailImg"=>"http://www.geonames.org/img/wikipedia/157000/thumb-156721-100.png", "lang"=>"en", "lat"=>33.786944444444444}, {"summary"=>"Walteria is a region of the city of Torrance in southern California. It is south of the Pacific Coast Highway. The local Zip code is 90505.", "distance"=>"3.1085", "rank"=>1, "title"=>"Walteria, California", "wikipediaUrl"=>"en.wikipedia.org/wiki/Walteria%2C_California", "elevation"=>34, "countryCode"=>"US", "lng"=>-118.35111111111111, "feature"=>"city", "geoNameId"=>5285212, "lang"=>"en", "lat"=>33.805}]}

# find_nearby_wikipedia  42.643018 18.107581: {"geonames"=>[{"summary"=>"St. Saviour Church is a small votive church located in the old town of Dubrovnik. It is dedicated to Jesus Christ.  (...)", "distance"=>"0.159", "rank"=>62, "title"=>"St. Saviour Church, Dubrovnik", "wikipediaUrl"=>"en.wikipedia.org/wiki/St._Saviour_Church%2C_Dubrovnik", "elevation"=>9, "lng"=>18.106944444444444, "feature"=>"landmark", "lang"=>"en", "lat"=>42.641666666666666}, {"summary"=>"Stradun or Placa (Stradone or Corso) is the main street of Dubrovnik, Croatia. The limestone-paved pedestrian street runs some 300 metres through the Old Town, the historic part of the city surrounded by the Walls of Dubrovnik (...)", "distance"=>"0.179", "rank"=>70, "title"=>"Stradun (street)", "wikipediaUrl"=>"en.wikipedia.org/wiki/Stradun_%28street%29", "elevation"=>16, "countryCode"=>"HR", "lng"=>18.108194444444447, "lang"=>"en", "lat"=>42.64147222222222}, {"summary"=>"Dubrovnik (Ragoùsa) is a city on the Adriatic Sea coast of Croatia, positioned at the terminal end of the Isthmus of Dubrovnik. It is one of the most prominent tourist destinations on the Adriatic, a seaport and the centre of Dubrovnik-Neretva county. Its total population is 42,641 (census 2011) (...)", "distance"=>"0.2809", "rank"=>100, "title"=>"Dubrovnik", "wikipediaUrl"=>"en.wikipedia.org/wiki/Dubrovnik", "elevation"=>9, "countryCode"=>"HR", "lng"=>18.10898888888889, "thumbnailImg"=>"http://www.geonames.org/img/wikipedia/3000/thumb-2713-100.jpg", "geoNameId"=>7577034, "lang"=>"en", "lat"=>42.64071388888889}, {"summary"=>"Fort Lovrijenac or St. Lawrence Fortress, often called \"Dubrovnik's Gibraltar\", is a fortress and theater located outside the western wall of the city of Dubrovnik in Croatia, 37 m above sea level. Tim Emert. Retrieved 2009-11-05 (...)", "distance"=>"0.3373", "rank"=>45, "title"=>"Lovrijenac", "wikipediaUrl"=>"en.wikipedia.org/wiki/Lovrijenac", "elevation"=>22, "lng"=>18.108, "feature"=>"landmark", "lang"=>"en", "lat"=>42.64}, {"summary"=>"The Walls of Dubrovnik are a series of defensive stone walls that have surrounded and protected the citizens of the afterward proclaimed maritime city-state of Dubrovnik (Ragusa), situated in southern Croatia, since the city's founding prior to the 7th century as a Byzantium castrum on a rocky (...)", "distance"=>"0.3373", "rank"=>97, "title"=>"Walls of Dubrovnik", "wikipediaUrl"=>"en.wikipedia.org/wiki/Walls_of_Dubrovnik", "elevation"=>22, "lng"=>18.108, "lang"=>"en", "lat"=>42.64}]}
# #####################
