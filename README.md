# geocoding-utils
tools for assisting geocoding from free sources

## add_geocoded_columns.sh: 

Skript to bulk geocode an input file.

The input file (csv-file) must be tab-separated, with the first line being a header bearing the following column names:

* addr:housenumber
* addr:street
* addr:city
* addr:country (as 2-letter-code)

The fields must not be empty!
It is advised to create an input file with export from e.g. libreoffice calc:

* "save as", choose:
 * File Type: CSV
 * check "Edit filter settings"
* click "Save", in the next box choose
 * Charset: UTF-8
 * Field delimiter: {Tab}
* OK

look here for an example input file: 
  testaddresses.csv

It generates 3 output files.

look here for an example output files: 
  testaddresses.exactgeocoded.csv.new.reference
  testaddresses.onlyroad.csv.new.reference
  testaddresses.unsuccessful.csv.new.reference
