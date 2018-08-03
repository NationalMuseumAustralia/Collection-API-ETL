#!/bin/bash
# Run the NMA API ETL end-to-end (SPARQL store load, extraction, Solr load)
# Orchestrates the entire ETL process, archiving loaded files and log files
#
# Intended to be run periodically via cron as root user
# But can be run manually: sudo ./etl-run-all.sh [full|incr]
#
# EMu exports a new set of files into the full or incr directory daily
# Emu files should be moved after ingest (as etl loads all *.xml files found)
# Piction exports a single file that is constantly over-written daily
# Piction file is not to be moved after ingest (so may be stale if export fails)

# we mainly work/archive in the EMu dir (but pull in piction files too)
DATA_DIR=/mnt/emu_data
PICTION_DATA_DIR=/mnt/dams_data
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

# Create output directory, eg: /mnt/emu_data/etl/yyyy-mm/job_yyyymmdd_hhmm_full
JOB_ID=job_$(date +"%Y%m%d_%H%M")_$MODE
JOB_DIR=$(date +"%Y-%m")
OUT_DIR="$DATA_DIR/etl/$JOB_DIR/$JOB_ID"
mkdir -p "$OUT_DIR"

# Init logfile
LOGFILE="$OUT_DIR/etl-run-all.log"
to_log() {
  echo $(date +"%Y-%m-%d %H:%M:%S") $1 >> $LOGFILE
}
to_log "BEGIN ETL - mode=$MODE, job=$JOB_ID"

# ETL step 1 - load to sparql store
cd $SCRIPT_DIR
IN_DIR="$DATA_DIR/$MODE"
PICTION_IN_DIR="$PICTION_DATA_DIR"

# check for existence of data files; if any are missing, abort the ETL
echo Checking for existence of source data files ... >> $LOGFILE
if compgen -G $IN_DIR/*object*.xml > /dev/null ; then
        echo Objects file exists >> $LOGFILE
else
        echo Objects file missing! ETL aborting. >> $LOGFILE
        exit 1
fi
if compgen -G $IN_DIR/*narratives*.xml > /dev/null ; then
        echo Narratives file exists >> $LOGFILE
else
        echo Narratives file missing! ETL aborting.  >> $LOGFILE
        exit 1
fi
if compgen -G $IN_DIR/*accessionlots*.xml > /dev/null ; then
        echo Accession lots file exists >> $LOGFILE
else
        echo Accession lots file missing! ETL aborting.  >> $LOGFILE
        exit 1
fi
if compgen -G $IN_DIR/*sites*.xml > /dev/null ; then
        echo Sites file exists >> $LOGFILE
else
        echo Sites file missing! ETL aborting.  >> $LOGFILE
        exit 1
fi
if compgen -G $IN_DIR/*parties*.xml > /dev/null ; then
        echo Parties file exists >> $LOGFILE
else
        echo Parties file missing! ETL aborting.  >> $LOGFILE
        exit 1
fi
if compgen -G $PICTION_IN_DIR/solr_prod1.xml > /dev/null ; then
        echo Piction file exists >> $LOGFILE
else
        echo Piction file missing! ETL aborting.  >> $LOGFILE
        exit 1
fi
case "$MODE" in
	full)
		to_log "START STEP 1 - full load to Fuseki SPARQL store"
		to_log "Source files: $(ls $IN_DIR/*.xml 2>/dev/null) $(ls $PICTION_IN_DIR/*.xml 2>/dev/null)"
		to_log "Loading files to Fuseki public dataset"
		$SCRIPT_DIR/etl-to-fuseki-full.sh public
		to_log "Loading files to Fuseki internal dataset"
		$SCRIPT_DIR/etl-to-fuseki-full.sh internal
		;;
	incremental)
		to_log "START STEP 1 - incremental load to Fuseki SPARQL store"
		to_log "Source files: $(ls $IN_DIR/*.xml 2>/dev/null) $(ls $PICTION_IN_DIR/*.xml 2>/dev/null)"
		to_log "Loading files to Fuseki public dataset"
		$SCRIPT_DIR/etl-to-fuseki-incremental.sh public
		to_log "Loading files to Fuseki internal dataset"
		$SCRIPT_DIR/etl-to-fuseki-incremental.sh internal
		;;
	*)
		to_log "Unknown mode: $MODE"
		echo Usage: $0 [full\|incremental]
		exit 1
esac
to_log "FINISH STEP 1 - load to Fuseki SPARQL store"

# move/copy loaded files and log
# (we're not allowed to move piction files)
cp $LOGS_DIR/etl-to-fuseki*.log $OUT_DIR/
mv $IN_DIR/*.xml $OUT_DIR 2>/dev/null
cp $PICTION_IN_DIR/*.xml $OUT_DIR 2>/dev/null
to_log "Moved/copied ingested files to archive: $OUT_DIR"

# ETL step 2 - extract from sparql store and load to solr
to_log "START STEP 2 - sparql extraction and Solr load"
cd $SCRIPT_DIR
$SCRIPT_DIR/etl-to-solr.sh public $MODE
cp $LOGS_DIR/etl-to-solr-public.log $OUT_DIR/
$SCRIPT_DIR/etl-to-solr.sh internal $MODE
cp $LOGS_DIR/etl-to-solr-internal.log $OUT_DIR/
to_log "FINISH STEP 2 - sparql extraction and Solr load"
to_log "Copied Solr load log files to archive: $OUT_DIR"

# delete stale archives
to_log "Removing old data files (14 days):"
find $DATA_DIR/etl -name *.xml -mtime +14 -print >> $LOGFILE
find $DATA_DIR/etl -name *.xml -mtime +14 -exec rm '{}' \;
to_log "Removing old etl job logs (6 months):"
# NB: using 7 months as may delete the whole 6 month directory 
find $DATA_DIR/etl -mindepth 1 -type d -ctime +214 -print >> $LOGFILE
find $DATA_DIR/etl -mindepth 1 -type d -ctime +214 -exec rm -rf '{}' \;

# end of run
cp $LOGS_DIR/etl-run-cron.log $OUT_DIR/
# NB: don't need to copy etl-run-all.log as is already in the output dir
to_log "END ETL - mode=$MODE, job=$JOB_ID"
exit 0
