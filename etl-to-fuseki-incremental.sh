#!/bin/bash
# Incremental ETL script
# Updates the RDF datasets from updated XML, using the SPARQL graph store protocol

# default to public dataset
DATASET=public

# Optional command-line arg to override dataset to internal
if (( $# > 0 ))
then
  DATASET="$1"
fi

cd /usr/local/NMA-API-ETL
java -Xmx4G -jar /usr/local/xmlcalabash/xmlcalabash.jar etl-to-fuseki.xpl incremental="true" dataset="$DATASET" > "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1
