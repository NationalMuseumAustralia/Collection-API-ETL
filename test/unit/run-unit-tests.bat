REM
REM Run unit tests using XSpec within XProc

set CALABASH_HOME=C:/project/lib/xmlcalabash-1.1.16-98
set XSPEC_HOME=file:///C:/project/lib/xspec/
set XSPEC_DATA_DIR_IN=file:///C:/Project/Git/NMA/NMA-API-ETL/test
set XSPEC_DATA_DIR_OUT=file:///C:/Project/Stage/NMA-unit-test-output

REM Create unit test output directory
mkdir "%XSPEC_DATA_DIR_OUT%"/unit/tests

REM EMu to CRM conversion unit tests
set XSPEC_IN="%XSPEC_DATA_DIR_IN%"/unit/tests/emu-to-crm.xspec
set XSPEC_OUT="%XSPEC_DATA_DIR_OUT%"/unit/tests/emu-to-crm-test-result.html
java -cp "%CALABASH_HOME%"/xmlcalabash-1.1.16-98.jar com.xmlcalabash.drivers.Main -i source="%XSPEC_IN%" -p xspec-home="%XSPEC_HOME%" -o result="%XSPEC_OUT%" "%XSPEC_HOME%"/src/harnesses/saxon/saxon-xslt-harness.xproc 
