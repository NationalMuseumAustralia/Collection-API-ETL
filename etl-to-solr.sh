#!/bin/bash

# default to public dataset
DATASET=public
JOBDIR=/tmp

# Optional command-line args to override dataset and jobdir
if (( $# > 0 ))
then
  DATASET="$1"
fi
if (( $# > 1 ))
then
  JOBDIR="$2"
fi

# run
time java -Xmx4G -XX:+UseStringDeduplication -XX:+UseG1GC -jar /usr/local/xmlcalabash/xmlcalabash.jar etl-to-solr.xpl dataset="$DATASET" > "/var/log/NMA-API-ETL/etl-to-solr-$DATASET.log" 2>&1

# copy log
cp "/var/log/NMA-API-ETL/etl-to-solr-$DATASET.log" "$OUT_DIR/"
