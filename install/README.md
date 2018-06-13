# NMA API server initialisation

Installs and configures software for the NMA API on a bare Ubuntu server.  

## Usage

Notes
* Add the appropriate server name before execution, e.g. `./install.sh "data.nma.gov.au"` 
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
git clone https://github.com/Conal-Tuohy/NMA-API-ETL.git
cd /usr/local/NMA-API-ETL/install
chmod a+x install.sh
./install.sh "<hostname>"
exit
```

Set passwords
* Add the appropriate passwords below before execution

```sh
sudo su -
htpasswd -bc /etc/apache2/admin-users.htpasswd nagiosadmin <admin-password>
htpasswd -b  /etc/apache2/admin-users.htpasswd admin <admin-password>
htpasswd -b  /etc/apache2/admin-users.htpasswd nmaapi <staff-password>
htpasswd -bc /etc/apache2/graph-store-users.htpasswd admin <admin-password>
htpasswd -b  /etc/apache2/graph-store-users.htpasswd nmaapi <staff-password>
/usr/share/webmin/changepass.pl /etc/webmin root <admin-password>
exit
```
