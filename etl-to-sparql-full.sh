#!/bin/bash
# Full ETL script
# Regenerates the full RDF dataset using the Graph Store's batch loading feature rather than the much slower SPARQL graph store protocol

# first remove any .nq files from previous execution of the pipeline
find /data/public/n-quads/ -name "*.nq" -delete
find /data/internal/n-quads/ -name "*.nq" -delete

# execute XML-to-RDF transformations to generate new .nq files in /data/public/n-quads/
cd /usr/local/NMA-API-ETL
java -Xmx4G -jar /usr/local/xmlcalabash/xmlcalabash.jar etl-to-sparql.xpl incremental="false" dataset="public" > /var/log/NMA-API-ETL/etl-to-sparql.log 2>&1
java -Xmx4G -jar /usr/local/xmlcalabash/xmlcalabash.jar etl-to-sparql.xpl incremental="false" dataset="internal" >> /var/log/NMA-API-ETL/etl-to-sparql.log 2>&1

# stop fuseki in order to rebuild its tdb2 database
sudo java -Xmx1G -jar /usr/local/xmlcalabash/xmlcalabash.jar manage-tomcat.xpl command="stop?path=/fuseki"
sleep 5
# delete fuseki's lock file which why doesn't fuseki delete it itself?
rm /etc/fuseki/databases/public/tdb.lock
# delete fuseki's datasets
rm -r -f /etc/fuseki/databases/public/*
rm -r -f /etc/fuseki/databases/internal/*

# assemble all the nquads files (which contain single graphs) into a single nquads file containing the entire RDF dataset
# first delete any old dataset files which may have been left lying around
rm /data/public/dataset.nq
rm /data/internal/dataset.nq

# concatenate n-quads files into new dataset file
find /data/public/n-quads/ -name "*.nq" | xargs cat >> /data/public/dataset.nq
find /data/internal/n-quads/ -name "*.nq" | xargs cat >> /data/internal/dataset.nq

# now remove the individual .nq files 
find /data/public/n-quads/ -name "*.nq" -delete
find /data/internal/n-quads/ -name "*.nq" -delete

# rebuild the fuseki db from the dataset files
echo Building Fuseki public dataset ...
time sudo -u tomcat8 /usr/local/jena/bin/tdb2.tdbloader --tdb=/etc/fuseki/configuration/public.ttl /data/public/dataset.nq >> /var/log/NMA-API-ETL/etl-to-sparql.log
echo Building Fuseki internal dataset ...
time sudo -u tomcat8 /usr/local/jena/bin/tdb2.tdbloader --tdb=/etc/fuseki/configuration/internal.ttl /data/internal/dataset.nq >> /var/log/NMA-API-ETL/etl-to-sparql.log

# delete the dataset nquads files now they've been imported into Fuseki
rm /data/public/dataset.nq
rm /data/internal/dataset.nq

# restart fuseki server 
sudo java -Xmx1G -jar /usr/local/xmlcalabash/xmlcalabash.jar manage-tomcat.xpl command="start?path=/fuseki"
