#!/bin/bash
echo =========== Installing Exim Mail Transfer Agent
HOSTNAME=`hostname`
# pre-fill exim package configuration
echo "exim4-config exim4/dc_localdelivery select mbox format in /var/mail/" | debconf-set-selections
echo "exim4-config exim4/dc_local_interfaces string 127.0.0.1 ; ::1" | debconf-set-selections
echo "exim4-config exim4/dc_other_hostnames string localhost" | debconf-set-selections
echo "exim4-config exim4/dc_minimaldns boolean false" | debconf-set-selections
echo "exim4-config exim4/dc_relay_domains string" | debconf-set-selections
echo "exim4-config	exim4/dc_readhost	string	nma.gov.au" | debconf-set-selections
echo "exim4-config exim4/use_split_config boolean false" | debconf-set-selections
#echo "exim4-config exim4/dc_eximconfig_configtype select internet site; mail is sent and received directly using SMTP" | debconf-set-selections
echo "exim4-config	exim4/dc_eximconfig_configtype	select	mail sent by smarthost; no local mail" | debconf-set-selections
echo "exim4-config exim4/dc_relay_nets string	" | debconf-set-selections
#echo "exim4-config	exim4/no_config	boolean	true" | debconf-set-selections
echo "exim4-config exim4/dc_postmaster string conal.tuohy+nma-dev-postmaster@gmail.com" | debconf-set-selections
echo "exim4-config	exim4/dc_smarthost	string	10.66.0.58"  | debconf-set-selections
echo exim4-config exim4/mailname string $HOSTNAME | debconf-set-selections
apt install -y sendemail exim4
update-exim4.conf
sendemail -f '"Installer" installer@data.nma.gov.au' -t conal.tuohy+exim-install-notice@gmail.com -u 'exim installation' -m "This message sent by exim"