#!/bin/bash

# written by Michael Maier (s.8472@aon.at)
# 
# 26.04.2016   - intial release
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
Usage: $0 [OPTIONS] {input-file.csv}

$0 is a program to download all data from a list of ids from the transformap api and output one geojson file

takes one argument, a csv-file with 2 columns: name,url (of each single dataset)


OPTIONS:
   -h -help --help     this help text

EOH
fi

###
### variables
###

INPUT_FILE=entpoints.csv
if [ "$1" ]; then
  INPUT_FILE="$1"
fi

OUTPUT_FILE="all_transformap_data.geojson"


###
### working part
###

echo '{"type":"FeatureCollection","features":[' > $OUTPUT_FILE

first_line="yes"
while read -r line
do
  url=`echo $line|cut -f 2 -d","`
  if [ "$url" = "url" ]; then
    continue
  fi

  if [ "$first_line" == "yes" ]; then
    first_line="no"
  else
    echo "," >>$OUTPUT_FILE
  fi

  features_geojson_array=`curl -s $url|jq ".features"`
  echo "$features_geojson_array" | head --lines=-1|tail -n +2 >> $OUTPUT_FILE

done < "$INPUT_FILE"

echo ']}' >> $OUTPUT_FILE
