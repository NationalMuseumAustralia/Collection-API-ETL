#!/bin/bash
# For testing on Amazon cloud instance; runs the full ETL without also moving any source data files
./etl-to-sparql-full.sh
./etl-to-solr.sh
