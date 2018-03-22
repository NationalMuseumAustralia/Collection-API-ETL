#!/bin/bash
# Run unit tests using XSpec within XProc

CALABASH_HOME=/usr/local/xmlcalabash
XSPEC_HOME=file:///usr/local/xspec/
XSPEC_DATA_DIR_IN=/usr/local/NMA-API-ETL/test
XSPEC_DATA_DIR_OUT=/usr/local/NMA/test-results

# Create unit test output director
mkdir -p "$XSPEC_DATA_DIR_OUT"/unit/tests

# EMu to CRM conversion unit tests
XSPEC_IN="$XSPEC_DATA_DIR_IN"/unit/tests/emu-to-crm.xspec
XSPEC_OUT="$XSPEC_DATA_DIR_OUT"/unit/tests/emu-to-crm-test-result.html
java -cp "$CALABASH_HOME"/xmlcalabash-1.1.16-98.jar com.xmlcalabash.drivers.Main -i source="$XSPEC_IN" -p xspec-home="$XSPEC_HOME" -o result="$XSPEC_OUT" "$XSPEC_HOME"/src/harnesses/saxon/saxon-xslt-harness.xproc 
