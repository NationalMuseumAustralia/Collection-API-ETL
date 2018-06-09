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
mv /etc/hostname /etc/hostname.original
echo "$HOSTNAME" > /etc/hostname
hostname $HOSTNAME
echo -e "127.0.0.1 localhost $HOSTNAME nma\n\n$(cat /etc/hosts)" > /etc/hosts
#
# JAVA
#
apt install -y default-jdk
JAVA_HOME=/usr/lib/jvm/default-java
echo "JAVA_HOME=/usr/lib/jvm/default-java" > /etc/environment
#
# APACHE HTTP SERVER
#
echo =========== Installing Apache HTTP Server
apt install -y apache2
a2enmod proxy_http
a2enmod headers
a2enmod ssl
mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.original
mv /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.original
ln -s $CONFIG_DIR/apache/000-default.conf /etc/apache2/sites-available/
ln -s $CONFIG_DIR/apache/default-ssl.conf /etc/apache2/sites-available/
#
# TOMCAT
#
echo =========== Installing tomcat
apt install -y tomcat8
mv /etc/default/tomcat8 /etc/default/tomcat8.original 
ln -s $CONFIG_DIR/tomcat/tomcat8 /etc/default/
#
# SOLR
#
echo =========== Installing Solr
cd $INSTALL_DIR
wget http://archive.apache.org/dist/lucene/solr/7.2.1/solr-7.2.1.tgz -O solr-7.2.1.tgz
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
# JENA
#
echo =========== Installing Jena
apt install -y unzip
cd $INSTALL_DIR
wget http://archive.apache.org/dist/jena/binaries/apache-jena-3.6.0.zip -O jena-3.6.0.zip
unzip jena-3.6.0.zip -d /usr/local
ln -s /usr/local/apache-jena-3.6.0 /usr/local/jena
#
# FUSEKI
#
echo =========== Installing Fuseki
mkdir -p /etc/fuseki/configuration
ln -s $CONFIG_DIR/fuseki/public.ttl /etc/fuseki/configuration/
chown -R tomcat8:tomcat8 /etc/fuseki/
cd $INSTALL_DIR
wget http://archive.apache.org/dist/jena/binaries/apache-jena-fuseki-3.6.0.zip -O fuseki-3.6.0.zip
unzip -j fuseki-3.6.0.zip apache-jena-fuseki-3.6.0/fuseki.war -d /var/lib/tomcat8/webapps/
#
# XML Calabash (XProc processor)
# - it may be better to just download the zip and unpack it in the appropriate place? (the installer uses /opt/xmlcalabash-blah-blah-version-number)
#
echo =========== Installing XML Calabash
cd $INSTALL_DIR
wget https://github.com/ndw/xmlcalabash1/releases/download/1.1.21-98/xmlcalabash-1.1.21-98.zip -O xmlcalabash.zip
unzip xmlcalabash.zip -d /usr/local
# create version-independent path for xmlcalabash executable: /usr/local/xmlcalabash/xmlcalabash.jar
ln -s /usr/local/xmlcalabash-1.1.21-98 /usr/local/xmlcalabash
ln -s /usr/local/xmlcalabash/xmlcalabash-1.1.21-98.jar /usr/local/xmlcalabash/xmlcalabash.jar
#
# XSpec (XSLT unit tests)
#
echo =========== Installing XSpec
cd /usr/local
git clone https://github.com/xspec/xspec.git
mkdir -p /usr/local/NMA/test-results
chown -R ubuntu:ubuntu /usr/local/NMA
#
# XPROC-Z (ETL)
#
echo =========== Installing XProc-Z ETL
cd $INSTALL_DIR
wget https://github.com/Conal-Tuohy/XProc-Z/releases/download/1.0c/xproc-z.war -O xproc-z.war
mv xproc-z.war /var/lib/tomcat8/webapps/
ln -s $CONFIG_DIR/tomcat/xproc-z.xml /var/lib/tomcat8/conf/Catalina/localhost/
mkdir /var/log/NMA-API-ETL
mkdir /data
chown ubuntu:ubuntu /data
# set up crontab to run ETL
cp $CONFIG_DIR/run-etl-crontab /etc/cron.d/
#
# XPROC-Z (API SHIM)
#
echo =========== Installing XProc-Z API shim
mkdir /etc/xproc-z/
chmod a+w /etc/xproc-z/
cp /var/lib/tomcat8/webapps/xproc-z.war /etc/xproc-z/
cd /etc/xproc-z/
git clone https://github.com/Conal-Tuohy/NMA-API.git
cp /etc/xproc-z/NMA-API/apiexplorer.html /var/www/html/
#
# KONG API GATEWAY
#
echo =========== Installing Kong
cd $INSTALL_DIR
wget https://bintray.com/kong/kong-community-edition-deb/download_file?file_path=dists/kong-community-edition-0.13.0.xenial.all.deb -O kong.deb
apt install -y ./kong.deb
apt-get install postgresql postgresql-client
sudo -u postgres psql --command="CREATE USER kong;"
sudo -u postgres psql --command="ALTER USER kong WITH PASSWORD 'kong';"
sudo -u postgres psql --command="CREATE DATABASE kong OWNER kong;"
ln -s $CONFIG_DIR/kong/kong.conf /etc/kong/
kong migrations up
kong stop
cp $CONFIG_DIR/kong/kong.service /etc/systemd/system/
systemctl enable kong
service kong start
# configure Kong
sudo java -Xmx1G -jar /usr/local/xmlcalabash/xmlcalabash.jar $CONFIG_DIR/kong/initialize-kong.xpl
#
# KONGA UI
#
echo =========== Installing Konga UI
# nodejs
cd $INSTALL_DIR
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.9/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 8 --lts --latest-npm
nvm use 8
apt install -y nodejs-legacy
npm install -g bower
npm install -g gulp
npm install -g sails
npm install -g sails-postgresql --save
# konga
cd /etc
git clone https://github.com/pantsel/konga.git
cd /etc/konga
npm run bower-deps
npm install
ln -s $CONFIG_DIR/konga/local.conf /etc/konga/config/
# database
sudo -u postgres psql --command="CREATE USER konga;"
sudo -u postgres psql --command="ALTER USER konga WITH PASSWORD 'konga';"
sudo -u postgres psql --command="CREATE DATABASE konga_database OWNER konga;"
sudo -u postgres PGOPTIONS='--client-min-messages=warning' psql -X -q -1 -v ON_ERROR_STOP=1 --pset pager=off -d konga_database -f $CONFIG_DIR/konga/konga_db_setup.sql -L konga_restore.log
# service - https://certsimple.com/blog/deploy-node-on-linux
cd /etc/konga
sed -i '1 i\#!/usr/bin/env' app.js
chmod a+x app.js
cp $CONFIG_DIR/konga/konga.service /etc/systemd/system/
systemctl enable konga
service konga start
#
# NAGIOS
#
echo =========== Installing Nagios
apt install -y autoconf gcc libc6 make wget unzip apache2 php libapache2-mod-php7.0 libgd2-xpm-dev
cd $INSTALL_DIR
wget -O nagioscore-4.3.4.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.3.4.tar.gz
tar xzf nagioscore-4.3.4.tar.gz
cd $INSTALL_DIR/nagioscore-nagios-4.3.4/
./configure --with-httpd-conf=/etc/apache2/sites-enabled
make all
useradd nagios
usermod -a -G nagios www-data
make install
make install-init
update-rc.d nagios defaults
make install-commandmode
make install-config
make install-webconf
a2enmod rewrite
a2enmod cgi
ufw allow Apache
ufw reload
apt install -y autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext
cd $INSTALL_DIR
wget --no-check-certificate -O nagios-plugins-2.2.1.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
tar zxf nagios-plugins-2.2.1.tar.gz
cd $INSTALL_DIR/nagios-plugins-release-2.2.1/
./tools/setup
./configure
make
make install
#
# WEBMIN
#
echo =========== Installing Webmin
sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -
apt update
apt install -y webmin
#
# GOACCESS
#
echo =========== Installing GoAccess
echo "deb http://deb.goaccess.io/ $(lsb_release -cs) main" | tee -a /etc/apt/sources.list.d/goaccess.list
wget -O - https://deb.goaccess.io/gnugpg.key | apt-key add -
apt update
apt install -y goaccess
mv /etc/goaccess.conf /etc/goaccess.conf.original
ln -s $CONFIG_DIR/goaccess/goaccess.conf /etc/
cp $CONFIG_DIR/goaccess/goaccess.service /etc/systemd/system/
systemctl enable goaccess
service goaccess start
#
# REFRESH
#
echo =========== Restarting services
service apache2 restart
service tomcat8 restart
service solr restart
service nagios restart
service webmin restart
service goaccess restart
#
echo =========== API server install complete
date
