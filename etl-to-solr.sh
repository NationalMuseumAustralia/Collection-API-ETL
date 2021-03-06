#!/bin/bash

# default to public dataset
DATASET=public

# default to "full" repopulation of Solr
MODE=full

# Optional command-line arg to override dataset
if (( $# > 0 ))
then
  DATASET="$1"
fi
if (( $# > 1 ))
then
  MODE="$2"
fi
# run

# restart Fuseki to minimize memory usage before starting the next phase of the ETL pipeline
java -Xmx1G -jar /usr/local/xmlcalabash/xmlcalabash.jar manage-tomcat.xpl command="stop?path=/fuseki" >> "/var/log/NMA-API-ETL/etl-to-solr-$DATASET.log" 2>&1
java -Xmx1G -jar /usr/local/xmlcalabash/xmlcalabash.jar manage-tomcat.xpl command="start?path=/fuseki" >> "/var/log/NMA-API-ETL/etl-to-solr-$DATASET.log" 2>&1
sleep 5
echo 1 > /proc/sys/vm/drop_caches
# Ensure that OS does not grant this process memory which it does not actually have available. 
# With vm.overcommit_memory=0 (the default), the process may start, but when it attempts to actually use the memory it has acquired,
# the kernel may find there's not enough available, and kill some other random process to free up memory. With vm.overcommit_memory=2,
# a failure to allocate memory will simply prevent this process from starting, and vm.overcommit_ratio=100 tells the kernel to allow 100% of memory
# to be allocated. See https://engineering.pivotal.io/post/virtual_memory_settings_in_linux_-_the_problem_with_overcommit/
/sbin/sysctl vm.overcommit_memory=2
/sbin/sysctl vm.overcommit_ratio=100
time java -Xmx3G -Xms3G -XX:+UseStringDeduplication -XX:+UseG1GC -jar /usr/local/xmlcalabash/xmlcalabash.jar etl-to-solr.xpl dataset="$DATASET" mode="$MODE" > "/var/log/NMA-API-ETL/etl-to-solr-$DATASET.log" 2>&1
