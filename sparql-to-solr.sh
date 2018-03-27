#!/bin/bash
time java -Xmx2G -jar /usr/local/xmlcalabash/xmlcalabash-1.1.16-98.jar sparql-to-solr.xpl > /var/log/NMA-API-ETL/sparql-to-solr.log 2>&1 &

