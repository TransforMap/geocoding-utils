#!/bin/bash

# written by Michael Maier (s.8472@aon.at)
# 
# 30.03.2016   - intial release
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
Usage: $0 file.geojson [OPTIONS] 

$0 is a program to take a geojson Feature-Collection and bulk upload data to 
the TransforMap API

OPTIONS:
   -h -help --help     this help text

EOH
fi

###
### variables
###

infile="$1"

workdir="single"

endpoint="https://data.transformap.co/place/"

resultfile="ids.csv"

###
### working part
###

mkdir -p "$workdir"

if [ ! -f "$resultfile" ]; then
  echo "name, id, uri" > "$resultfile"
fi

counter=0
while true; do
  result=`cat "$infile"|jq ".features[$counter]"`

  if [ "$result" = "null" ]; then
    echo "finished after $counter items."
    exit
  fi
  fname=$workdir/$counter.geojson
  echo "$result" > $fname
  name=`echo "$result" | jq ".properties.name"`

  id=`curl -s $endpoint "-d@$fname" -H 'content-type: application/json' | jq ".id"|sed 's/"//g'`
  echo "name: '$name', id: $id"
  echo "$name, $id, $endpoint$id" >> $resultfile

  let counter=$counter+1
done
