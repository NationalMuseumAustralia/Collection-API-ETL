#!/bin/bash
# Run unit tests using XSpec within XProc

CALABASH_HOME=/usr/local/xmlcalabash
XSPEC_HOME=file:///usr/local/xspec/
XSPEC_DATA_DIR_IN=/usr/local/NMA-API-ETL/test
XSPEC_DATA_DIR_OUT=/usr/local/NMA/test-results

# Create unit test output director
mkdir -p "$XSPEC_DATA_DIR_OUT"/unit/tests

# Function to run the specified unit test
run_test() {
  echo ================= TEST $1 =================
  XSPEC_IN="$XSPEC_DATA_DIR_IN"/unit/tests/$1.xspec
  XSPEC_OUT="$XSPEC_DATA_DIR_OUT"/unit/tests/$1-test-result.html
  java -cp "$CALABASH_HOME"/xmlcalabash-1.1.16-98.jar com.xmlcalabash.drivers.Main -i source="$XSPEC_IN" -p xspec-home="$XSPEC_HOME" -o result="$XSPEC_OUT" "$XSPEC_HOME"/src/harnesses/saxon/saxon-xslt-harness.xproc 
}

# Optional command-line arg for a single test to run
if (( $# > 1 ))
then
  run_test "$1"
else
  run_test date-util-functions
  run_test xmljson-functions
  run_test emu-to-crm-common
  run_test emu-to-crm-object
  run_test emu-to-crm-narrative
  run_test emu-to-crm-party
  run_test emu-to-crm-place
  run_test emu-to-crm-collection
  run_test emu-to-crm-filter
  run_test piction-to-media
  run_test trix-description-redact-emu-image
  run_test trix-description-redact-object
  run_test trix-description-redact-object-norights
  run_test trix-description-redact-narrative
  run_test trix-description-to-dc-object
  run_test trix-description-to-dc-narrative
  run_test trix-description-to-dc-media
  run_test trix-description-to-dc-party
  run_test trix-description-to-solr-object
  run_test trix-description-to-solr-narrative
  run_test trix-description-to-solr-party
fi
