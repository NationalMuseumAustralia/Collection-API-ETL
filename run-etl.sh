#!/bin/bash
# Run the NMA API ETL end-to-end (SPARQL store load, extraction, Solr load)
# Orchestrates the entire ETL process, archiving loaded files and log files
# NB: Piction files are not to be moved after ingest (so may be stale)
#
# Intended to be run periodically via cron as root user
# But can be run manually: sudo run-etl.sh [full|incr]

# we mainly work/archive in the EMu dir (but pull in piction files too)
DATA_DIR=/mnt/emudata
PICTION_DATA_DIR=/mnt/damsdata
# where the main steps operations are
SCRIPT_DIR=/usr/local/NMA-API-ETL
# where to find ETL logs (to copy/archive after each step)
LOGS_DIR=/var/log/NMA-API-ETL
# default to full load
MODE=full

# Optional command-line arg to override mode
if (( $# > 0 ))
then
  MODE="$1"
fi

# Create output directory, eg: /mnt/emudata/full/job_yyyy-mm-dd_hh-mm-ss
JOB_ID=job_$(date +"%Y-%m-%d_%H-%M-%S")
OUT_DIR="$DATA_DIR/$MODE/$JOB_ID"
mkdir -p "$OUT_DIR"

# Init logfile
LOGFILE="$OUT_DIR/run-etl.log"
to_log() {
  echo $(date +"%Y-%m-%d %H:%M:%S") $1 >> $LOGFILE
}
to_log "ETL start - mode=$MODE, job=$JOB_ID"

# ETL step 1 - load to sparql store
IN_DIR="$DATA_DIR/$MODE"
PICTION_IN_DIR="$PICTION_DATA_DIR/$MODE"
case "$MODE" in
	full)
		to_log "Starting full load to SPARQL store"
		to_log "Source files: $(ls $IN_DIR/*.xml 2>/dev/null) $(ls $PICTION_IN_DIR/*.xml 2>/dev/null)"
		$SCRIPT_DIR/etl-full.sh
		;;
	incr|incremental)
		to_log "Starting incremental load to SPARQL store"
		to_log "Source files: $(ls $IN_DIR/*.xml 2>/dev/null) $(ls $PICTION_IN_DIR/*.xml 2>/dev/null)"
		$SCRIPT_DIR/etl-incremental.sh
		;;
	*)
		to_log "Unknown mode: $MODE"
		echo Usage: $0 [full\|incremental]
		exit 1
esac
to_log "Finished load to SPARQL store"

# move/copy loaded files and log
# (we're not allowed to move piction files)
cp $LOGS_DIR/etl.log $OUT_DIR/
mv $IN_DIR/*.xml $OUT_DIR 2>/dev/null
cp $PICTION_IN_DIR/*.xml $OUT_DIR 2>/dev/null
to_log "Moved/copied ingested files to archive: $OUT_DIR"

# ETL step 2 - extract from sparql store and load to solr
to_log "Starting extraction and Solr load"
$SCRIPT_DIR/sparql-to-solr.sh
to_log "Finished extraction and Solr load"
# copy log
cp $LOGS_DIR/sparql-to-solr.log $OUT_DIR/
to_log "Copied Solr load log file to archive: $OUT_DIR"

# log finished
to_log "ETL finished - mode=$MODE, job=$JOB_ID"
exit 0
