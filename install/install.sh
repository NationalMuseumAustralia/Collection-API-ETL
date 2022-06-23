#!/bin/bash
#
# NMA API server init script
#
# See README for usage instructions.
#
HOSTNAME=data.nma.gov.au
CONFIG_DIR=/usr/local/NMA-API-ETL/install/config
INSTALL_DIR=/tmp/nma-api-install
#
echo =========== API server install start
date
# install utilities
# 
echo =========== Installing utility programs
# used to unzip the emu data files which are downloaded in a zip file
apt install -y unzip

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
mv /etc/hostname /etc/hostname.original
echo "$HOSTNAME" > /etc/hostname
hostname $HOSTNAME
echo -e "127.0.0.1 localhost $HOSTNAME nma\n\n$(cat /etc/hosts)" > /etc/hosts
#
# EXIM MAIL TRANSFER AGENT
#
echo =========== Installing Exim Mail Transfer Agent
chmod a+x $CONFIG_DIR/exim/configure.sh
$CONFIG_DIR/exim/configure.sh

# pre-fill exim package configuration
echo "exim4-config exim4/use_split_config boolean false" | debconf-set-selections
echo "exim4-config exim4/dc_other_hostnames string localhost" | debconf-set-selections
echo "exim4-config exim4/dc_relay_domains string" | debconf-set-selections
echo "exim4-config exim4/dc_relay_nets string" | debconf-set-selections
echo "exim4-config exim4/dc_localdelivery select mbox format in /var/mail/" | debconf-set-selections
echo "exim4-config exim4/dc_eximconfig_configtype select internet site; mail is sent and received directly using SMTP" | debconf-set-selections
echo "exim4-config exim4/dc_postmaster string conal.tuohy+nma-dev-postmaster@gmail.com" | debconf-set-selections
echo "exim4-config exim4/dc_local_interfaces string 127.0.0.1 ; ::1" | debconf-set-selections
echo exim4-config exim4/mailname string $HOSTNAME | debconf-set-selections
echo "exim4-config exim4/dc_minimaldns boolean false" | debconf-set-selections
apt install -y sendemail exim4
update-exim4.conf
#sendemail -f '"Installer" installer@data.nma.gov.au' -t conal.tuohy@gmail.com -u 'exim installation' -m "This message sent by exim"
#
# JAVA
#
echo =========== Installing Java
apt install -y default-jdk
JAVA_HOME=/usr/lib/jvm/default-java
echo "JAVA_HOME=/usr/lib/jvm/default-java" >> /etc/environment
#
# APACHE HTTP SERVER
#
echo =========== Installing Apache HTTP Server
apt install -y apache2
a2enmod proxy_http
a2enmod headers
a2enmod ssl
# to receive X-Forward-For from F5 proxy server
a2enmod remoteip
mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.original
ln -s $CONFIG_DIR/apache/000-default.conf /etc/apache2/sites-available/
#
# TOMCAT
#
echo =========== Installing tomcat
apt install -y tomcat9 
mv /etc/default/tomcat9 /etc/default/tomcat9.original 
ln -s $CONFIG_DIR/tomcat/tomcat9 /etc/default/
#
# SOLR
#
echo =========== Installing Solr
cd $INSTALL_DIR
SOLR_VERSION=9.0.0
wget https://archive.apache.org/dist/solr/solr/$SOLR_VERSION/solr-$SOLR_VERSION.tgz -O solr-$SOLR_VERSION.tgz
tar xzf solr-$SOLR_VERSION.tgz solr-$SOLR_VERSION/bin/install_solr_service.sh --strip-components=2 
./install_solr_service.sh $INSTALL_DIR/solr-$SOLR_VERSION.tgz 

# create cores, only link config parts (so data files aren't in git)
SOLR_CORE_1_NAME=core_nma_public
mkdir -p        /var/solr/data/$SOLR_CORE_1_NAME
chown solr:solr /var/solr/data/$SOLR_CORE_1_NAME
ln -s $CONFIG_DIR/solr/$SOLR_CORE_1_NAME/core.properties /var/solr/data/$SOLR_CORE_1_NAME/core.properties
ln -s $CONFIG_DIR/solr/$SOLR_CORE_1_NAME/conf            /var/solr/data/$SOLR_CORE_1_NAME/conf

SOLR_CORE_2_NAME=core_nma_internal
mkdir -p        /var/solr/data/$SOLR_CORE_2_NAME
chown solr:solr /var/solr/data/$SOLR_CORE_2_NAME
ln -s $CONFIG_DIR/solr/$SOLR_CORE_2_NAME/core.properties /var/solr/data/$SOLR_CORE_2_NAME/core.properties
ln -s $CONFIG_DIR/solr/$SOLR_CORE_2_NAME/conf            /var/solr/data/$SOLR_CORE_2_NAME/conf

SOLR_CORE_3_NAME=core_nma_log
mkdir -p        /var/solr/data/$SOLR_CORE_3_NAME
chown solr:solr /var/solr/data/$SOLR_CORE_3_NAME
ln -s $CONFIG_DIR/solr/$SOLR_CORE_3_NAME/core.properties /var/solr/data/$SOLR_CORE_3_NAME/core.properties
ln -s $CONFIG_DIR/solr/$SOLR_CORE_3_NAME/conf            /var/solr/data/$SOLR_CORE_3_NAME/conf

# replace Solr's default "includes" (config) file with a customised version
mv /etc/default/solr.in.sh /etc/default/solr.in.sh.original
ln -s $CONFIG_DIR/solr/solr.in.sh /etc/default/solr.in.sh
# solr dynamically updates schema files so needs write permission
chown -R solr:solr $CONFIG_DIR/solr

#
# JENA
#
echo =========== Installing Jena
apt install -y unzip
cd $INSTALL_DIR
wget https://archive.apache.org/dist/jena/binaries/apache-jena-4.5.0.zip -O jena-4.5.0.zip
unzip jena-4.5.0.zip -d /usr/local
ln -s /usr/local/apache-jena-4.5.0 /usr/local/jena
#
# FUSEKI
#
echo =========== Installing Fuseki
mkdir -p /etc/fuseki/configuration
ln -s $CONFIG_DIR/fuseki/log4j.properties /etc/fuseki/
ln -s $CONFIG_DIR/fuseki/public.ttl /etc/fuseki/configuration/
ln -s $CONFIG_DIR/fuseki/internal.ttl /etc/fuseki/configuration/
chown -R tomcat:tomcat /etc/fuseki/
cd $INSTALL_DIR
wget https://archive.apache.org/dist/jena/binaries/jena-fuseki-war-4.5.0.war -O /var/lib/tomcat9/webapps/fuseki.war
#
# XML Calabash (XProc processor)
# - it may be better to just download the zip and unpack it in the appropriate place? (the installer uses /opt/xmlcalabash-blah-blah-version-number)
#
echo =========== Installing XML Calabash
cd $INSTALL_DIR
wget https://github.com/ndw/xmlcalabash1/releases/download/1.4.1-100/xmlcalabash-1.4.1-100.zip -O xmlcalabash.zip
unzip xmlcalabash.zip -d /usr/local
# create version-independent path for xmlcalabash executable: /usr/local/xmlcalabash/xmlcalabash.jar
ln -s /usr/local/xmlcalabash-1.4.1-100 /usr/local/xmlcalabash
ln -s /usr/local/xmlcalabash/xmlcalabash-1.4.1-100.jar /usr/local/xmlcalabash/xmlcalabash.jar
#
## TOMCAT MANAGER
#
echo =========== Installing tomcat manager
apt install -y tomcat9-admin
# configure tomcat-users.xml to include credentials for manager app
java -Xmx1G -jar /usr/local/xmlcalabash/xmlcalabash.jar $CONFIG_DIR/tomcat/initialize-tomcat.xpl
# restrict read access to the tomcat-users.xml file to root and tomcat users
chown root:tomcat /var/lib/tomcat9/conf/tomcat-users.xml
chmod u=rw,g=r,o= /var/lib/tomcat9/conf/tomcat-users.xml
# restart tomcat to reload the new tomcat-users.xml
service tomcat9 restart
#
# XSpec (XSLT unit tests)
#
echo =========== Installing XSpec
cd /usr/local
git clone https://github.com/xspec/xspec.git
mkdir -p /usr/local/NMA/test-results
# TODO decide about ownership
#chown -R ubuntu:ubuntu /usr/local/NMA
#
# XPROC-Z (ETL)
#
echo =========== Installing XProc ETL
mkdir /var/log/NMA-API-ETL
#chown -R ubuntu:ubuntu /mnt
mkdir -p /data/source
mkdir -p /data/public/n-quads
mkdir -p /data/internal/n-quads
#chown -R ubuntu:ubuntu /data
# set up crontab to run ETL
chmod a+x /usr/local/NMA-API-ETL/etl-run-all.sh
cp $CONFIG_DIR/run-apietl-crontab /etc/cron.d/
#
# XPROC-Z (API SHIM)
#
echo =========== Installing XProc-Z API shim
cd $INSTALL_DIR
mkdir /etc/xproc-z/
cd /etc/xproc-z/
chmod a+w .
wget https://github.com/Conal-Tuohy/XProc-Z/releases/download/1.5.1/xproc-z.war -O xproc-z.war
git clone https://github.com/NationalMuseumAustralia/Collection-API.git NMA-API
ln -s $CONFIG_DIR/tomcat/xproc-z.xml /var/lib/tomcat9/conf/Catalina/localhost/
# Install API Explorer front end application
echo =========== Installing API Explorer
cp /etc/xproc-z/NMA-API/apiexplorer.html /var/www/html/
#
# KONG API GATEWAY
#
echo =========== Installing Kong
cd $INSTALL_DIR
# Add Kong as an APT repository and install Kong Community Edition
echo "deb [trusted=yes] https://download.konghq.com/gateway-2.x-ubuntu-xenial/ default all" | sudo tee /etc/apt/sources.list.d/kong.list
apt-get update
apt install -y kong=2.8.1
apt install -y postgresql postgresql-client
sudo -u postgres psql --command="CREATE USER kong;"
sudo -u postgres psql --command="ALTER USER kong WITH PASSWORD 'kong';"
sudo -u postgres psql --command="CREATE DATABASE kong OWNER kong;"
# TODO Compare Kong's default config
#ln -s $CONFIG_DIR/kong/kong.conf /etc/kong/
#kong migrations up
#kong stop
#cp $CONFIG_DIR/kong/kong.service /etc/systemd/system/
#systemctl enable kong
#service kong start
# configure Kong
#java -Xmx1G -jar /usr/local/xmlcalabash/xmlcalabash.jar $CONFIG_DIR/kong/initialize-kong.xpl
#
# REFRESH
#
echo =========== Restarting services
service apache2 restart
service tomcat8 restart
service solr restart
#
echo =========== API server install complete
date
