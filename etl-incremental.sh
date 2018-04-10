#!/bin/bash
# Incremental ETL script
# Updates the RDF dataset from updated XML, using the SPARQL graph store protocol

sudo java -Xmx2G -jar /usr/local/xmlcalabash/xmlcalabash-1.1.16-98.jar etl.xpl incremental="true" > /var/log/NMA-API-ETL/etl.log 2>&1 &
