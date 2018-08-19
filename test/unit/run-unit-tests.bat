@ECHO OFF
:: Run unit tests using XSpec within XProc
:: https://github.com/xspec/xspec/wiki/Running-with-XProc

set CALABASH_HOME=%USERPROFILE%\lib\xmlcalabash-1.1.21-98
set XSPEC_DATA_DIR_IN=%USERPROFILE%\Git\NMA\Collection-API-ETL\test
set XSPEC_DATA_DIR_OUT=C:\Project\Stage\NMA-unit-test-output
set XSPEC_HOME=%USERPROFILE%\lib\xspec\

:: Create unit test output directory
mkdir "%XSPEC_DATA_DIR_OUT%\unit\tests"

:: Optional command-line arg for a single test to run
IF NOT %1.==. (
  CALL :runtest "%1"
  GOTO :end
)

CALL :runtest date-util-functions
CALL :runtest xmljson-functions
CALL :runtest emu-to-crm-common
CALL :runtest emu-to-crm-object
CALL :runtest emu-to-crm-narrative
CALL :runtest emu-to-crm-party
CALL :runtest emu-to-crm-place
CALL :runtest emu-to-crm-collection
CALL :runtest emu-to-crm-filter
CALL :runtest piction-to-media
CALL :runtest trix-description-redact-emu-image
CALL :runtest trix-description-redact-object
CALL :runtest trix-description-redact-object-norights
CALL :runtest trix-description-redact-narrative
CALL :runtest trix-description-to-dc-object
CALL :runtest trix-description-to-dc-narrative
CALL :runtest trix-description-to-dc-media
CALL :runtest trix-description-to-dc-party
CALL :runtest trix-description-to-solr-object
CALL :runtest trix-description-to-solr-narrative
CALL :runtest trix-description-to-solr-party
CALL :runtest build-solr

:end
EXIT /B %ERRORLEVEL%

:: function to run the specified unit test
:runtest
ECHO ================= TEST %~1 =================
:: NB: ':\=/' converts Windows filepaths from backslash to forward-slash 
set XSPEC_IN=%XSPEC_DATA_DIR_IN:\=/%/unit/tests/%~1%.xspec
set XSPEC_OUT=%XSPEC_DATA_DIR_OUT:\=/%/unit/tests/%~1%-test-result.html
java -cp %CALABASH_HOME%\xmlcalabash-1.1.21-98.jar com.xmlcalabash.drivers.Main -i source=%XSPEC_IN% -p xspec-home=file:///%XSPEC_HOME:\=/% -o result=%XSPEC_OUT% %XSPEC_HOME%src\harnesses\saxon\saxon-xslt-harness.xproc
EXIT /B 0
