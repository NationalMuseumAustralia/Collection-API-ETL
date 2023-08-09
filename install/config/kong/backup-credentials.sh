#!/bin/sh
java -cp /usr/local/xmlcalabash/xmlcalabash.jar:/usr/local/xmlcalabash/lib/slf4j-simple-1.7.36.jar com.xmlcalabash.drivers.Main /usr/local/NMA-API-ETL/install/config/kong/backup-credentials.xpl output=kong-credentials.xml
