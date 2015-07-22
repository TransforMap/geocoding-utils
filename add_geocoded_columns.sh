#!/bin/bash

# written by Michael Maier (s.8472@aon.at)
# 
# 05.11.2013   - intial release
# Wed  1 Jul 16:08:07 CEST 2015 - update for TransforMap
#

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.

###
### Standard help text
###

if [ ! "$1" ] || [ "$1" = "-h" ] || [ "$1" = " -help" ] || [ "$1" = "--help" ]
then 
cat <<EOH
Usage: $0 filename [OPTIONS] 

$0 is a program to add addr infos via nominatim to osm data in csv format
  - actually it has to be tab-separated. 
  The following columns have to be present:
  • housenumber
  • street
  • city
  • country (as 2-letter-code)

OPTIONS:
   -h -help --help     this help text

EOH
exit
fi

###
### variables
###

# OSM_OBJECT_TYPE=[N|W|R]
# N if osm_id < 1000000000000000
# W if osm_id > 1000000000000000
# R if osm_id > 2000000000000000

#nominatim_columns_folder="nominatim-columns/" #there are files *.ncolumn, with name like the column from nominatim and the target csv column as file content
#nominatim_columns_folder_entries=$(cd $nominatim_columns_folder; ls *ncolumn; cd ..)

nominatim_addr="http://nominatim.openstreetmap.org/search"
nominatim_format="xml"

#csv-file-format: first line header: @id, @lon, @lat, some addr:* - these are the ones we are interested.

filename="$1"
new_filename=$filename.new

quality_column="$filename.qual-column"
lat_column="$filename.lat-column"
lon_column="$filename.lon-column"

nr_of_lines=$(wc -l $filename|cut -f 1 -d" ")
let percentage=$nr_of_lines/100

###
### working part
###

firstline_passed=0

line_counter=0

line_counter=0
actual_percentage=0

# Problem: when in a field a user has written an <enter>, reading file line per line gets scrambled...
# only files without enters in text cells can be used!
# Tip: in OpenOffice, search&replace: CTRL-H, Search for: \n, replace with: \\n, MUST use other options: Regular expression

while read -r line
do
 #   echo "line: $line"
    let line_counter=$line_counter+1
    if [ "$line_counter" = "$percentage" ]; then
        line_counter=0
        let actual_percentage=$actual_percentage+1
        echo "actual_percentage=$actual_percentage %"
    fi

    #extract street, h-nr, city, 
    #first line is header
    if [ "$firstline_passed" = "0" ]; then
        header="$line"
        echo $header
        nr_of_cols=$(echo "$header"| grep -P '\t' -o |wc -l)+1
        echo "nr_of_cols: $nr_of_cols"

        # FIXME if header columns contain space, counters are garbage...

        housenumber_column="notfound"
        for (( counter=1; counter <= nr_of_cols; counter++ )); do
            item=$(echo "$header"|cut -f $counter)
            item=$(echo "$item"|sed 's/"//g')
            echo "$item"
            if [ "$item" = "housenumber" ]; then
                housenumber_column=$counter
            fi
            if [ "$item" = "street" ]; then
                street_column=$counter
            fi
            if [ "$item" = "postcode" ]; then
                postcode_column=$counter
            fi
            if [ "$item" = "state" ]; then
                state_column=$counter
            fi
            if [ "$item" = "city" ]; then
                city_column=$counter
            fi
            if [ "$item" = "country" ]; then
                country_column=$counter
            fi
        done
        echo "Found at columns: city: $city_column, postcode: $postcode_column, street: $street_column, housenumber: $housenumber_column, state: $state_column, country: $country_column."

        firstline_passed=1
        echo "note" > $quality_column
        echo "lat" > $lat_column
        echo "lon" > $lon_column
        continue
    fi

    # wget-string bauen, 
    # output parsen, 
    # * es können mehrere sein!
    # in neue datei schreiben, zum schluss hinpasten
    country="&countrycodes=$(echo "$line"| cut -f $country_column)"
    city="&city=$(echo "$line"| cut -f $city_column)"
    #postcode=$(echo "$line"| cut -f $postcode_column)
    street=$(echo "$line"| cut -f $street_column)
    if [ "$housenumber_column" != "notfound" ]; then
      housenumber=$(echo "$line"| cut -f $housenumber_column)
    fi
    if [ "$state_column" ]; then
      state="&state=$(echo "$line"| cut -f $state_column)"
    fi
    # must be inserted before street in nominatim call with a space
    if [ "$housenumber" ];then
        housenumber="$housenumber%20"
    fi
    #echo -n "city: $city, postcode: $postcode, street: $street, housenumber: $housenumber. "


    # with postcodes we get less results, omit.

    details_contents=$(wget -q "$nominatim_addr?street=$housenumber$street$city$country$state&format=xml&addressdetails=1&email=s.8472@aon.at" -O - | sed -e 's/></>\n</g')
    #echo "$details_contents"
    echo "obj call: street=$housenumber$street$city$country$state"
    length=$(echo "$details_contents"|grep "^<place"|wc -l)
    echo "$details_contents"|grep "^<place"
    class=$(echo "$details_contents"|grep "^<place"|sed -e "s/^.*class='//" -e "s/' type=.*$//" |sort|uniq|sed -e ':a;N;$!ba;s/\n/; /g')
    osm_type=$(echo "$details_contents"|grep -m 1 "^<place"|grep -o "osm_type='[a-z]*"|sed -e "s/^osm_type='//")
    echo "type: $osm_type"

    #echo "l: „$length”"
    if [ "$class" = "" ] && [ "$length" != "0" ]; then
        echo "class „$class”, „$details_contents”"
    fi
    if [ "$length" = "0" ]; then
        class="unknown in osm"
    fi
    #echo "$class"
    if ! [ "$class" ]; then
        echo "ERROR: $details_contents"
        echo
    fi
    if [ "$class" = "highway" ]; then 
        class="Information only from road"
    else if [ "$class" = "place" ] && [ "$osm_type" = "way" ]; then
        class="interpolation"
    else if [ "$class" != "unknown in osm" ]; then
        class="exact"
    fi
    fi
    fi 

    echo "$class" >> $quality_column

    lat=$(echo "$details_contents"|grep -m 1 "^<place"|grep -o "lat='[0-9.-]*'"|grep -o "[0-9.-]*")
    lon=$(echo "$details_contents"|grep -m 1 "^<place"|grep -o "lon='[0-9.-]*'"|grep -o "[0-9.-]*")
    echo "$lat" >> $lat_column
    echo "$lon" >> $lon_column

done < "$filename"

paste $filename $lat_column $lon_column $quality_column > $filename.new
rm $lat_column $lon_column $quality_column

exit

