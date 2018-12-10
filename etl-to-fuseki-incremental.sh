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
# Ensure that OS does not grant this process memory which it does not actually have available. 
# With vm.overcommit_memory=0 (the default), the process may start, but when it attempts to actually use the memory it has acquired,
# the kernel may find there's not enough available, and kill some other random process to free up memory. With vm.overcommit_memory=2,
# a failure to allocate memory will simply prevent this process from starting.
sysctl vm.overcommit_memory=2
java -Xmx3G -Xms3G -jar /usr/local/xmlcalabash/xmlcalabash.jar etl-to-fuseki.xpl incremental="true" dataset="$DATASET" > "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1
