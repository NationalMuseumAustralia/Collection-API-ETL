#!/bin/sh
java -cp /usr/local/xmlcalabash/xmlcalabash.jar:/usr/local/xmlcalabash/lib/slf4j-simple-1.7.36.jar com.xmlcalabash.drivers.Main /usr/local/NMA-API-ETL/install/config/kong/restore-credentials.xpl input=production-kong-credentials.xml
