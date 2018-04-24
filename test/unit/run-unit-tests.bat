@ECHO OFF
:: Run unit tests using XSpec within XProc

set CALABASH_HOME=C:/project/lib/xmlcalabash-1.1.16-98
set XSPEC_HOME=file:///C:/project/lib/xspec/
set XSPEC_DATA_DIR_IN=file:///C:/Project/Git/NMA/NMA-API-ETL/test
set XSPEC_DATA_DIR_OUT=file:///C:/Project/Stage/NMA-unit-test-output

:: Create unit test output directory
mkdir "%XSPEC_DATA_DIR_OUT%"/unit/tests

REM XXX CALL :runtest date-util-functions
REM XXX CALL :runtest xmljson-functions
REM XXX CALL :runtest emu-to-crm-common
REM XXX CALL :runtest emu-to-crm-object
REM XXX CALL :runtest emu-to-crm-narrative
REM XXX CALL :runtest emu-to-crm-party
REM XXX CALL :runtest emu-to-crm-place
REM XXX CALL :runtest emu-to-crm-collection
REM XXX CALL :runtest trix-description-to-dc-object
CALL :runtest trix-description-to-dc-narrative
REM XXX CALL :runtest trix-description-to-dc-media
REM XXX CALL :runtest trix-description-to-solr-object

:: end of main logic
EXIT /B %ERRORLEVEL%

:: function to run the specified unit test
:runtest
ECHO ================= TEST %~1 =================
set XSPEC_IN="%XSPEC_DATA_DIR_IN%"/unit/tests/%~1%.xspec
set XSPEC_OUT="%XSPEC_DATA_DIR_OUT%"/unit/tests/%~1%-test-result.html
java -cp "%CALABASH_HOME%"/xmlcalabash-1.1.16-98.jar com.xmlcalabash.drivers.Main -i source="%XSPEC_IN%" -p xspec-home="%XSPEC_HOME%" -o result="%XSPEC_OUT%" "%XSPEC_HOME%"/src/harnesses/saxon/saxon-xslt-harness.xproc 
EXIT /B 0