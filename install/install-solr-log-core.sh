#!/bin/bash
# Install the Solr core "core_nma_log to be used as a log target by the Collections API service
CONFIG_DIR=/usr/local/NMA-API-ETL/install/config
SOLR_CORE_3_NAME=core_nma_log
mkdir -p        /var/solr/data/$SOLR_CORE_3_NAME
chown solr:solr /var/solr/data/$SOLR_CORE_3_NAME
ln -s $CONFIG_DIR/solr/$SOLR_CORE_3_NAME/core.properties /var/solr/data/$SOLR_CORE_3_NAME/core.properties
ln -s $CONFIG_DIR/solr/$SOLR_CORE_3_NAME/conf            /var/solr/data/$SOLR_CORE_3_NAME/conf
