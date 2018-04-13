@ECHO OFF
REM
REM Run unit tests using XSpec within XProc

set CALABASH_HOME=C:/project/lib/xmlcalabash-1.1.16-98
set XSPEC_HOME=file:///C:/project/lib/xspec/
set XSPEC_DATA_DIR_IN=file:///C:/Project/Git/NMA/NMA-API-ETL/test
set XSPEC_DATA_DIR_OUT=file:///C:/Project/Stage/NMA-unit-test-output

REM Create unit test output directory
mkdir "%XSPEC_DATA_DIR_OUT%"/unit/tests

REM Date util functions unit tests
set XSPEC_IN="%XSPEC_DATA_DIR_IN%"/unit/tests/date-util-functions.xspec
set XSPEC_OUT="%XSPEC_DATA_DIR_OUT%"/unit/tests/date-util-test-result.html
java -cp "%CALABASH_HOME%"/xmlcalabash-1.1.16-98.jar com.xmlcalabash.drivers.Main -i source="%XSPEC_IN%" -p xspec-home="%XSPEC_HOME%" -o result="%XSPEC_OUT%" "%XSPEC_HOME%"/src/harnesses/saxon/saxon-xslt-harness.xproc 

REM xml-to-json functions unit tests
set XSPEC_IN="%XSPEC_DATA_DIR_IN%"/unit/tests/xmljson-functions.xspec
set XSPEC_OUT="%XSPEC_DATA_DIR_OUT%"/unit/tests/xmljson-test-result.html
java -cp "%CALABASH_HOME%"/xmlcalabash-1.1.16-98.jar com.xmlcalabash.drivers.Main -i source="%XSPEC_IN%" -p xspec-home="%XSPEC_HOME%" -o result="%XSPEC_OUT%" "%XSPEC_HOME%"/src/harnesses/saxon/saxon-xslt-harness.xproc 

REM EMu to CRM conversion unit tests
set XSPEC_IN="%XSPEC_DATA_DIR_IN%"/unit/tests/emu-to-crm.xspec
set XSPEC_OUT="%XSPEC_DATA_DIR_OUT%"/unit/tests/emu-to-crm-test-result.html
java -cp "%CALABASH_HOME%"/xmlcalabash-1.1.16-98.jar com.xmlcalabash.drivers.Main -i source="%XSPEC_IN%" -p xspec-home="%XSPEC_HOME%" -o result="%XSPEC_OUT%" "%XSPEC_HOME%"/src/harnesses/saxon/saxon-xslt-harness.xproc 

REM Trix to DC (object) conversion unit tests
set XSPEC_IN="%XSPEC_DATA_DIR_IN%"/unit/tests/trix-description-to-dc-object.xspec
set XSPEC_OUT="%XSPEC_DATA_DIR_OUT%"/unit/tests/trix-to-dc-object-test-result.html
java -cp "%CALABASH_HOME%"/xmlcalabash-1.1.16-98.jar com.xmlcalabash.drivers.Main -i source="%XSPEC_IN%" -p xspec-home="%XSPEC_HOME%" -o result="%XSPEC_OUT%" "%XSPEC_HOME%"/src/harnesses/saxon/saxon-xslt-harness.xproc 

REM Trix to DC (media) conversion unit tests
set XSPEC_IN="%XSPEC_DATA_DIR_IN%"/unit/tests/trix-description-to-dc-media.xspec
set XSPEC_OUT="%XSPEC_DATA_DIR_OUT%"/unit/tests/trix-to-dc-media-test-result.html
java -cp "%CALABASH_HOME%"/xmlcalabash-1.1.16-98.jar com.xmlcalabash.drivers.Main -i source="%XSPEC_IN%" -p xspec-home="%XSPEC_HOME%" -o result="%XSPEC_OUT%" "%XSPEC_HOME%"/src/harnesses/saxon/saxon-xslt-harness.xproc 

REM Trix to Solr (object) conversion unit tests
set XSPEC_IN="%XSPEC_DATA_DIR_IN%"/unit/tests/trix-description-to-solr-object.xspec
set XSPEC_OUT="%XSPEC_DATA_DIR_OUT%"/unit/tests/trix-to-solr-object-test-result.html
java -cp "%CALABASH_HOME%"/xmlcalabash-1.1.16-98.jar com.xmlcalabash.drivers.Main -i source="%XSPEC_IN%" -p xspec-home="%XSPEC_HOME%" -o result="%XSPEC_OUT%" "%XSPEC_HOME%"/src/harnesses/saxon/saxon-xslt-harness.xproc 
