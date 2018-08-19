# NMA API server updates

Updates and configures software for the NMA API on an existing Ubuntu server.  

## v1.0.0 - August 2018

Release documentation: [releases/tag/v1.0.0](https://github.com/NationalMuseumAustralia/Collection-API-ETL/releases/tag/v1.0.0)


```sh
sudo su -
cd /usr/local/NMA-API-ETL
git fetch --all
git checkout releases/tag/v0.1.0
service apache2 restart
service tomcat8 restart
service solr restart
service nagios restart
service webmin restart
exit
```

## v0.1.0 - August 2018

Release documentation: [releases/tag/v0.1.0](https://github.com/NationalMuseumAustralia/Collection-API-ETL/releases/tag/v0.1.0)

Initial public release.
