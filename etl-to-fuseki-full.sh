#!/bin/bash
# Full ETL script
# Regenerates the full RDF dataset using the Graph Store's batch loading feature rather than the much slower SPARQL graph store protocol

# default to public dataset
DATASET=public

# Optional command-line arg to override dataset to internal
if (( $# > 0 ))
then
  DATASET="$1"
fi

# first remove any .nq files from previous execution of the pipeline
find "/data/$DATASET/n-quads/" -name "*.nq" -delete

# execute XML-to-RDF transformations to generate new .nq files in /data/DATASET/n-quads/
cd /usr/local/NMA-API-ETL
java -Xmx4G -jar /usr/local/xmlcalabash/xmlcalabash.jar etl-to-fuseki.xpl incremental="false" dataset="$DATASET" > "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1

# stop fuseki in order to rebuild its tdb2 database
echo Stopping fuseki... >> "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1
sudo java -Xmx1G -jar /usr/local/xmlcalabash/xmlcalabash.jar manage-tomcat.xpl command="stop?path=/fuseki" >> "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1
sleep 5
# delete fuseki's lock files which why doesn't fuseki delete it itself?
rm "/etc/fuseki/databases/$DATASET/tdb.lock"
# delete fuseki's datasets
echo Deleting existing fuseki dataset files ... >> "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1
rm -r -f /etc/fuseki/databases/$DATASET/* >> "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1

# assemble all the nquads files (which contain single graphs) into a single nquads file containing the entire RDF dataset
# first delete any old dataset files which may have been left lying around
rm "/data/$DATASET/dataset.nq"

# concatenate n-quads files into new dataset file
echo Joining individual graphs into a single dataset file for import... >> "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1
find "/data/$DATASET/n-quads/" -name "*.nq" | xargs cat >> "/data/$DATASET/dataset.nq"

# now remove the individual .nq files 
find "/data/$DATASET/n-quads/" -name "*.nq" -delete >> "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1

# rebuild the fuseki db from the dataset files
echo Building Fuseki $DATASET dataset ... >> "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1
time sudo -u tomcat8 /usr/local/jena/bin/tdbloader --loc "/etc/fuseki/databases/$DATASET" "/data/$DATASET/dataset.nq" >> "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1

# generate triple pattern statistics for Fuseki query optimizer
# TODO switch back to TDB1 statistics generation
#echo Generating triple pattern statistics for $DATASET dataset ... >> "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1
#sudo -u tomcat8 /usr/local/jena/bin/tdb2.tdbstats --graph urn:x-arq:UnionGraph --loc "/etc/fuseki/databases/$DATASET" > "/tmp/stats-$DATASET.opt"
#sudo -u tomcat8 cp "/tmp/stats-$DATASET.opt" "/etc/fuseki/databases/$DATASET/"

# delete the dataset nquads files now they've been imported into Fuseki
rm "/data/$DATASET/dataset.nq"

# restart fuseki server 
echo Restarting fuseki ... >> "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1
sudo java -Xmx1G -jar /usr/local/xmlcalabash/xmlcalabash.jar manage-tomcat.xpl command="start?path=/fuseki" >> "/var/log/NMA-API-ETL/etl-to-fuseki-$DATASET.log" 2>&1
