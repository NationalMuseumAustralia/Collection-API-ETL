#!/bin/bash

# default to public dataset
DATASET=public

# Optional command-line arg to override dataset
if (( $# > 0 ))
then
  DATASET="$1"
fi

# run
time java -Xmx4G -XX:+UseStringDeduplication -XX:+UseG1GC -jar /usr/local/xmlcalabash/xmlcalabash.jar etl-to-solr.xpl dataset="$DATASET" > "/var/log/NMA-API-ETL/etl-to-solr-$DATASET.log" 2>&1
