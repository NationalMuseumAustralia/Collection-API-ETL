#!/bin/bash
# Run the NMA API ETL end-to-end
# Runs the entire ETL process, moving loaded files to archive and copying over logfiles
# Intended to be run periodically via cron 

DATA_DIR=/data
SCRIPT_DIR=/usr/local/NMA-API-ETL
# where to find ETL logs (we copy them into a central location afterwards)
LOGS_DIR=/var/log/NMA-API-ETL
# default to full load
MODE=full

# Optional command-line arg to override mode
if (( $# > 0 ))
then
  MODE="$1"
fi

# Create output directories, eg:
# - /data/full/yyyy-mm-dd_hh-mm-ss
# - /data/full/yyyy-mm-dd_hh-mm-ss/logs
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUT_DIR="$DATA_DIR/$MODE/$TIMESTAMP"
mkdir -p "$OUT_DIR"
mkdir -p "$OUT_DIR/logs"

# Init logfile
LOGFILE="$OUT_DIR/logs/run-etl.log"
to_log() {
  echo $(date +"%Y-%m-%d %H:%M:%S") $1
  echo $(date +"%Y-%m-%d %H:%M:%S") $1 >> $LOGFILE
}
to_log "ETL start - mode=$MODE, timestamp=$TIMESTAMP"

# ETL step 1 - load to sparql store
IN_DIR="$DATA_DIR/$MODE"
case "$MODE" in
	full)
		to_log "Starting full load to SPARQL store"
		to_log "XML files: $(ls $IN_DIR/*.xml 2>/dev/null)"
		$SCRIPT_DIR/etl-full.sh
		;;
	incremental)
		to_log "Starting incremental load to SPARQL store"
		to_log "XML files: $(ls $IN_DIR/*.xml 2>/dev/null)"
		$SCRIPT_DIR/etl-incremental.sh
		;;
	*)
		to_log "Unknown mode: $MODE"
		echo Usage: $0 [full\|incremental]
		exit 1
esac
to_log "Finished load to SPARQL store"

# move/copy loaded files and log
mv $IN_DIR/*.xml $OUT_DIR 2>/dev/null
cp $LOGS_DIR/etl.log $OUT_DIR/logs/
to_log "Moved loaded files to archive: $OUT_DIR"

# ETL step 2 - extract from sparql store and load to solr
to_log "Starting extraction and Solr load"
$SCRIPT_DIR/sparql-to-solr.sh
to_log "Finished extraction and Solr load"

# copy log
cp $LOGS_DIR/sparql-to-solr.log $OUT_DIR/logs/
to_log "Moved loaded files to archive: $OUT_DIR"

# log finished
to_log "ETL finished - mode=$MODE, timestamp=$TIMESTAMP"
exit 0
