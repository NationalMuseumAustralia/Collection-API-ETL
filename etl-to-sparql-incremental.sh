#!/bin/bash
# Incremental ETL script
# Updates the RDF dataset from updated XML, using the SPARQL graph store protocol

cd /usr/local/NMA-API-ETL
java -Xmx2G -jar /usr/local/xmlcalabash/xmlcalabash.jar etl.xpl incremental="true" > /var/log/NMA-API-ETL/etl-to-sparql.log 2>&1
