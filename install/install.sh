#!/bin/bash
#
# NMA API server init script
# 2018-02-26
#
# usage:
#
# > sudo su -
# > apt update
# NB: "apt upgrade" may require manual input
# > apt upgrade -y -f
# > apt install git -y
# > cd /usr/local
# > git clone https://github.com/Conal-Tuohy/NMA-API-ETL.git
# > cd /usr/local/NMA-API-ETL/install
# > chmod a+x install.sh
# NB: insert appropriate server name
# > ./install.sh "<hostname>"
# > exit
#
# NB: If the script stalls, may need to kill any 'apt' processes before re-running
# > ps -aux | grep 'apt'
# > sudo kill -9 <process-id>
# > sudo rm /var/cache/apt/archives/lock
#
HOSTNAME=nma.conaltuohy.com
CONFIG_DIR=/usr/local/NMA-API-ETL/install/config
INSTALL_DIR=/tmp/nma-api-install
#
date
mkdir $INSTALL_DIR
chown -R ubuntu:ubuntu /usr/local/NMA-API-ETL
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
# JAVA
#
apt install default-jdk -y
JAVA_HOME=/usr/lib/jvm/default-java
echo "JAVA_HOME=/usr/lib/jvm/default-java" > /etc/environment
#
# APACHE HTTP SERVER
#
echo =========== Installing Apache HTTP Server
apt install apache2 -y
a2enmod proxy_http
mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.original
ln -s $CONFIG_DIR/apache/000-default.conf /etc/apache2/sites-available/
#
# TOMCAT
#
echo =========== Installing tomcat
apt install tomcat8 -y
ln -s $CONFIG_DIR/tomcat/tomcat8 /etc/default/
#
# SOLR
#
echo =========== Installing Solr
cd $INSTALL_DIR
wget http://apache.mirror.digitalpacific.com.au/lucene/solr/7.2.1/solr-7.2.1.tgz -O solr-7.2.1.tgz
tar xzf solr-7.2.1.tgz solr-7.2.1/bin/install_solr_service.sh --strip-components=2
./install_solr_service.sh $INSTALL_DIR/solr-7.2.1.tgz
# create cores, only link config parts (so data files aren't in git)
SOLR_CORE_1_NAME=core_nma_public
SOLR_CORE_2_NAME=core_nma_internal
mkdir -p        /var/solr/data/$SOLR_CORE_1_NAME
chown solr:solr /var/solr/data/$SOLR_CORE_1_NAME
mkdir -p        /var/solr/data/$SOLR_CORE_2_NAME
chown solr:solr /var/solr/data/$SOLR_CORE_2_NAME
ln -s $CONFIG_DIR/solr/$SOLR_CORE_1_NAME/core.properties /var/solr/data/$SOLR_CORE_1_NAME/core.properties
ln -s $CONFIG_DIR/solr/$SOLR_CORE_1_NAME/conf            /var/solr/data/$SOLR_CORE_1_NAME/conf
ln -s $CONFIG_DIR/solr/$SOLR_CORE_2_NAME/core.properties /var/solr/data/$SOLR_CORE_2_NAME/core.properties
ln -s $CONFIG_DIR/solr/$SOLR_CORE_2_NAME/conf            /var/solr/data/$SOLR_CORE_2_NAME/conf
# solr dynamically updates schema files so needs write permission
chown -R solr:solr $CONFIG_DIR/solr
#
# FUSEKI
#
echo =========== Installing Fuseki
mkdir -p /etc/fuseki/configuration
ln -s $CONFIG_DIR/fuseki/public.ttl /etc/fuseki/configuration/
chown -R tomcat8:tomcat8 /etc/fuseki/
cd $INSTALL_DIR
wget http://apache.mirror.serversaustralia.com.au/jena/binaries/apache-jena-fuseki-3.6.0.zip -O fuseki-3.6.0.zip
apt install unzip
unzip -j fuseki-3.6.0.zip apache-jena-fuseki-3.6.0/fuseki.war -d /var/lib/tomcat8/webapps/
#
# XML Calabash
# - it may be better to just download the zip and unpack it in the appropriate place? (the installer uses /opt/xmlcalabash-blah-blah-version-number)
#
echo =========== Installing XML Calabash
cd $INSTALL_DIR
wget https://github.com/ndw/xmlcalabash1/releases/download/1.1.16-98/xmlcalabash-1.1.16-98.jar -O xmlcalabash-1.1.16-98.jar
echo 1 | java -jar ./xmlcalabash-1.1.16-98.jar
ln -s /usr/local/xmlcalabash-1.1.16-98 /usr/local/xmlcalabash
#
# XPROC-Z (ETL)
#
echo =========== Installing Xproc-Z ETL
cd $INSTALL_DIR
wget https://github.com/Conal-Tuohy/XProc-Z/releases/download/1.0c/xproc-z.war -O xproc-z.war
mv xproc-z.war /var/lib/tomcat8/webapps/
ln -s $CONFIG_DIR/tomcat/xproc-z.xml /var/lib/tomcat8/conf/Catalina/localhost/
#
# XPROC-Z (API SHIM)
#
echo =========== Installing Xproc-Z API shim
mkdir /etc/xproc-z/
chmod a+w /etc/xproc-z/
cp /var/lib/tomcat8/webapps/xproc-z.war /etc/xproc-z/
cd /etc/xproc-z/
git clone https://github.com/Conal-Tuohy/NMA-API.git
#
# REFRESH
#
echo =========== Restarting services
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
echo =========== API server install complete
date
