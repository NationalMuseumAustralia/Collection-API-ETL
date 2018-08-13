#!/bin/bash
echo =========== Installing Exim Mail Transfer Agent
apt install -y sendemail exim4
ln -s /usr/local/NMA-API-ETL/install/config/exim/update-exim4.conf.conf
update-exim4.conf
sendemail -f '"Installer" installer@data.nma.gov.au' -t conal.tuohy@gmail.com -u 'exim installation' -m "This message sent by exim"