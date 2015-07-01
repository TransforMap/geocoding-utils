# geocoding-utils
tools for assisting geocoding from free sources

## add_geocoded_columns.sh: 

Skript to bulk geocode an input file.

The input file (csv-file) must be tab-separated, with the first line being a header bearing the following column names:

* housenumber
* street
* city
* country (as 2-letter-code)

The fields must not be empty!
It is advised to create an input file with export from e.g. libreoffice calc:

* "save as", choose:
 * File Type: CSV
 * check "Edit filter settings"
* click "Save", in the next box choose
 * Charset: UTF-8
 * Field delimiter: {Tab}
* OK

look here for an example input file: testaddresses.csv

look here for an example output file: testaddresses.csv.new.reference
