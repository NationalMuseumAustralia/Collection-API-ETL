#!/bin/bash
echo =========== Installing Exim Mail Transfer Agent
# make sure sendemail is installed
apt install -y sendemail exim4
# remove existing exim4 config
rm /etc/exim4/update-exim4.conf.conf
# link to our custom exim4 config
ln -s /usr/local/NMA-API-ETL/install/config/exim/update-exim4.conf.conf /etc/exim4/
# generate exim4's actual configuration from the source above
update-exim4.conf
# send email to test
sendemail -f '"Installer" installer@data.nma.gov.au' -t conal.tuohy@gmail.com -u 'exim installation' -m "This message sent by exim"