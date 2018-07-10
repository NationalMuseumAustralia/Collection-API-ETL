#!/bin/bash
time java -Xmx2G -jar /usr/local/xmlcalabash/xmlcalabash.jar etl-to-solr.xpl dataset="internal" > /var/log/NMA-API-ETL/etl-to-solr.log 2>&1
time java -Xmx2G -jar /usr/local/xmlcalabash/xmlcalabash.jar etl-to-solr.xpl dataset="public" >> /var/log/NMA-API-ETL/etl-to-solr.log 2>&1

