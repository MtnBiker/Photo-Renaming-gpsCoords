# Not sure this is debugged completely. Ruby script more developed
fileName="/Users/gscar/Documents/Genealogy/City Directories/1880-89 Los Angeles City Directories/1886–7 Los Angeles City Directory. Bynon/1886–7 Los Angeles City Directory. Bynon. p221. Suzzalo.jpg"
year=""
month=""
day=""
time=" 12:00:0"
dateTime=$year:$month:$day$time

exiftool  -AllDates="1886:01:01 12:00:0" -overwrite_original $fileName
exiftool  -AllDates=$dateTime -overwrite_original $fileName