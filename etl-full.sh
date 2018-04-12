#!/bin/bash
# Full ETL script
# Regenerates the full RDF dataset using the Graph Store's batch loading feature rather than the much slower SPARQL graph store protocol

# first remove any .nq files from previous execution of the pipeline
find /data/public/n-quads/ -name "*.nq" -delete

# execute XML-to-RDF transformations to generate new .nq files in /data/public/n-quads/
java -Xmx2G -jar /usr/local/xmlcalabash/xmlcalabash-1.1.16-98.jar etl.xpl incremental="false" > /var/log/NMA-API-ETL/etl.log 2>&1

# stop fuseki in order to rebuild its tdb2 database
service tomcat8 stop
sleep 5
# delete fuseki's lock file which why doesn't fuseki delete it itself?
rm /etc/fuseki/databases/public/tdb.lock
# delete fuseki's dataset
rm -r -f /etc/fuseki/databases/public/*

# assemble all the nquads files (which contain single graphs) into a single nquads file containing the entire RDF dataset
# first delete old dataset file
rm /data/public/dataset.nq
# concatenate n-quads files into new dataset file
find /data/public/n-quads/ -name "*.nq" | xargs cat >> /data/public/dataset.nq

# rebuild the fuseki db from the dataset file
time sudo -u tomcat8 /usr/local/jena/bin/tdb2.tdbloader --tdb=/etc/fuseki/configuration/public.ttl /data/public/dataset.nq >> /var/log/NMA-API-ETL/etl.log

# restart fuseki server 
service tomcat8 start
