#!/bin/bash
# Incremental ETL script
# Updates the RDF datasets from updated XML, using the SPARQL graph store protocol

cd /usr/local/NMA-API-ETL
java -Xmx4G -jar /usr/local/xmlcalabash/xmlcalabash.jar etl-to-sparql.xpl incremental="true" dataset="public" > /var/log/NMA-API-ETL/etl-to-sparql.log 2>&1
java -Xmx4G -jar /usr/local/xmlcalabash/xmlcalabash.jar etl-to-sparql.xpl incremental="true" dataset="internal" >> /var/log/NMA-API-ETL/etl-to-sparql.log 2>&1
