# NMA API server initialisation

Installs and configures software for the NMA API on a bare Ubuntu server.  

## Usage

Notes
* Add the appropriate server name before execution, e.g. `./install.sh 'data.nma.gov.au'` 
* Some install steps may require manual input, e.g. `Do you want to continue? [Y/n]`
* The main install script takes around 15 minutes to run

```sh
sudo su -
timedatectl set-timezone Australia/Canberra
date
/etc/init.d/cron restart
export DEBIAN_FRONTEND=noninteractive
apt update
apt upgrade -y -f
apt install git -y
cd /usr/local
git clone https://github.com/NationalMuseumAustralia/Collection-API-ETL.git NMA-API-ETL
cd /usr/local/NMA-API-ETL/install
chmod a+x install.sh
./install.sh '<hostname>'
exit
```

Set passwords
* Key in appropriate passwords when prompted (except: replace password for webmin)

```sh
sudo su -
htpasswd -c /etc/apache2/admin-users.htpasswd admin
htpasswd    /etc/apache2/admin-users.htpasswd nagiosadmin
htpasswd    /etc/apache2/admin-users.htpasswd nmaapi
/usr/share/webmin/changepass.pl /etc/webmin root 'password'
exit
```
