#!/bin/bash
#
# NMA API server init script
# 2018-02-21
#
# usage:
#
# > sudo su -
# > apt install git
# > cd /usr/local
# > git clone https://github.com/Conal-Tuohy/NMA-API-ETL.git
# > cd /usr/local/NMA-API-ETL/install
# > ./install.sh "<hostname>" >> /var/log/nma-api-install.log 2>>&1 &
# > tail -f /var/log/nma-api-install.log
# > exit
#
HOSTNAME=nma.conaltuohy.com
CONFIG_DIR=/usr/local/NMA-API-ETL/install
INSTALL_DIR=/tmp/nma-api-install
#
date
mkdir $INSTALL_DIR
#
# HOST
#
if [[ -z "$1" ]]; then
    echo No hostname provided so using default hostname: $HOSTNAME
else
    HOSTNAME="$1"
fi
hostname $HOSTNAME
echo -e "127.0.0.1 localhost $HOSTNAME nma\n\n$(cat /etc/hosts)" > /etc/hosts
#
# APACHE SUITE
#
apt update
apt upgrade -y -f
# httpd
apt install apache2 -y
a2enmod proxy_http
mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.original
ln -s $CONFIG_DIR/config/apache/000-default.conf /etc/apache2/sites-available/
# tomcat
apt install tomcat8 -y
# solr
cd $INSTALL_DIR
wget http://apache.mirror.digitalpacific.com.au/lucene/solr/7.2.1/solr-7.2.1.tgz -O solr-7.2.1.tgz
tar xzf solr-7.2.1.tgz solr-7.2.1/bin/install_solr_service.sh --strip-components=2
./install_solr_service.sh $INSTALL_DIR/solr-7.2.1.tgz
# fuseki
mkdir -p /etc/fuseki/configuration
ln -s $CONFIG_DIR/config/fuseki/public.ttl /etc/fuseki/configuration/
chown -R tomcat8:tomcat8 /etc/fuseki/
wget http://apache.mirror.serversaustralia.com.au/jena/binaries/apache-jena-fuseki-3.6.0.zip -O /tmp/fuseki.zip
apt install unzip
unzip -j fuseki.zip apache-jena-fuseki-3.6.0/fuseki.war -d /var/lib/tomcat7/webapps/
# TODO update schema for Solr 7
# ln -s $CONFIG_DIR/config/solr/schema.xml /opt/solr/conf/
#
# XML Calabash
# - it may be better to just download the zip and unpack it in the appropriate place? (the installer uses /opt/xmlcalabash-blah-blah-version-number)
#
cd $INSTALL_DIR
wget https://github.com/ndw/xmlcalabash1/releases/download/1.1.16-98/xmlcalabash-1.1.16-98.jar -O xmlcalabash-1.1.16-98.jar
echo 1 | java -jar ./xmlcalabash-1.1.16-98.jar
ln -s /usr/local/xmlcalabash-1.1.16-98 /usr/local/xmlcalabash
#
# XPROC-Z (ETL)
#
cd $INSTALL_DIR
wget https://github.com/Conal-Tuohy/XProc-Z/releases/download/1.0c/xproc-z.war -O xproc-z.war
mv xproc-z.war /var/lib/tomcat8/webapps/
ln -s $CONFIG_DIR/config/tomcat/xproc-z.xml /var/lib/tomcat8/conf/Catalina/localhost/
#
# XPROC-Z (API SHIM)
#
mkdir /etc/xproc-z/
chmod a+w /etc/xproc-z/
cp /var/lib/tomcat8/webapps/xproc-z.war /etc/xproc-z/
cd /etc/xproc-z/
git clone https://github.com/Conal-Tuohy/NMA-API.git
#
# REFRESH
#
service apache2 restart
service tomcat8 restart
service solr restart
#
# DATA
#
#mkdir /data
#chmod a+w /data
#ln -s $CONFIG_DIR/data/Emu_* /data/
#
date
