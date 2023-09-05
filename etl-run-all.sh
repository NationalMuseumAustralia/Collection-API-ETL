#!/bin/bash
# Run the NMA API ETL end-to-end (SPARQL store load, extraction, Solr load)
# Orchestrates the entire ETL process, archiving loaded files and log files
#
# Intended to be run periodically via cron as root user
# But can be run manually: sudo ./etl-run-all.sh [full|incr]
DATA_DIR=/data
SOURCE_DIR=$DATA_DIR/source
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

# download the Piction xml file
echo Downloading Piction xml file ... >> $LOGFILE
curl --output $SOURCE_DIR/solr_prod.xml https://collectionsearch.nma.gov.au/nmacs-image-download/solr_prod.xml

# unpack the EMU data files, junking any directory structure and over-writing any existing files
# TODO delete existing files so that we can detect if there are XML files missing from source ZIP
echo Unpackaging EMU data files ... >> $LOGFILE
unzip -j -o /home/emu/emu.zip -d $SOURCE_DIR/ >> $LOGFILE

# check for existence of data files; if any are missing, abort the ETL
echo Checking for existence of source data files ... >> $LOGFILE
if compgen -G $SOURCE_DIR/*object*.xml > /dev/null ; then
	echo Objects file exists >> $LOGFILE
else
	echo Objects file missing! ETL aborting. >> $LOGFILE
	exit 1
fi
if compgen -G $SOURCE_DIR/*narratives*.xml > /dev/null ; then
	echo Narratives file exists >> $LOGFILE
else
	echo Narratives file missing! ETL aborting.  >> $LOGFILE
	exit 1
fi
if compgen -G $SOURCE_DIR/*accessionlots*.xml > /dev/null ; then
	echo Accession lots file exists >> $LOGFILE
else
	echo Accession lots file missing! ETL aborting.  >> $LOGFILE
	exit 1
fi
if compgen -G $SOURCE_DIR/*sites*.xml > /dev/null ; then
	echo Sites file exists >> $LOGFILE
else
	echo Sites file missing! ETL aborting.  >> $LOGFILE
	exit 1
fi
if compgen -G $SOURCE_DIR/*parties*.xml > /dev/null ; then
	echo Parties file exists >> $LOGFILE
else
	echo Parties file missing! ETL aborting.  >> $LOGFILE
	exit 1
fi
if compgen -G $SOURCE_DIR/solr_prod.xml > /dev/null ; then
	echo Piction file exists >> $LOGFILE
else
	echo Piction file missing! ETL aborting.  >> $LOGFILE
	exit 1
fi

to_log "START ETL STEP 1 - full load to Fuseki SPARQL store"
to_log "Source files: $(ls $SOURCE_DIR/*.xml 2>/dev/null) $(ls $SOURCE_DIR/*.xml 2>/dev/null)"
to_log "Loading files to Fuseki public dataset"
$SCRIPT_DIR/etl-to-fuseki-full.sh public
to_log "Loading files to Fuseki internal dataset"
$SCRIPT_DIR/etl-to-fuseki-full.sh internal

to_log "FINISH ETL STEP 1 - load to Fuseki SPARQL store"

# move/copy loaded files and log
# (we're not allowed to move piction files)
cp $LOGS_DIR/etl-to-fuseki*.log $OUT_DIR/
mv $SOURCE_DIR/*.xml $OUT_DIR 2>/dev/null
cp $SOURCE_DIR/*.xml $OUT_DIR 2>/dev/null
to_log "Moved/copied ingested files to archive: $OUT_DIR"

# ETL step 2 - extract from sparql store and load to solr
to_log "START ETL STEP 2 - load to Solr"
to_log "Loading files to Solr public core"
cd $SCRIPT_DIR
$SCRIPT_DIR/etl-to-solr.sh public $MODE
cp $LOGS_DIR/etl-to-solr-public.log $OUT_DIR/
to_log "Copied Solr public load log files to archive: $OUT_DIR"
to_log "Loading files to Solr internal core"
$SCRIPT_DIR/etl-to-solr.sh internal $MODE
cp $LOGS_DIR/etl-to-solr-internal.log $OUT_DIR/
to_log "Copied Solr internal load log files to archive: $OUT_DIR"
to_log "FINISH ETL STEP 2 - load to Solr"

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
mkdir $OUT_DIR/failed-solr-deposits
find $DATA_DIR/failed-solr-deposits -exec mv {} $OUT_DIR/failed-solr-deposits/ \;

# NB: don't need to copy etl-run-all.log as is already in the output dir
to_log "END ETL - mode=$MODE, job=$JOB_ID"
HOSTNAME=`hostname`
sendemail -f "$HOSTNAME ETL <no_reply@$HOSTNAME>" -t conal.tuohy@gmail.com api@nma.gov.au -u 'NMA ETL results' -m "See attached log file." -a $OUT_DIR/etl-run-all.log
exit 0
