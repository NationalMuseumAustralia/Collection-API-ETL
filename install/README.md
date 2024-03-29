# NMA API server initialisation

Installs and configures software for the NMA API on a bare Ubuntu server.  

### Data directories

The install script creates a `data` directory into which it will download XML data 
from Piction.

XML data from EMU should be uploaded, in a zip file named `emu.zip`, to the home folder
of the `emu` user, `/home/emu`

## Usage

Notes
* In the commands below, replace `<hostname>` with the appropriate server name, e.g. `./install.sh 'data.nma.gov.au'` 
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
git switch 2022-update
cd /usr/local/NMA-API-ETL/install
chmod a+x install.sh
./install.sh '<hostname>'
exit
```

### Set passwords

Key in appropriate passwords when prompted 

```sh
sudo su -
touch /etc/apache2/admin-users.htpasswd
htpasswd /etc/apache2/admin-users.htpasswd admin
htpasswd /etc/apache2/admin-users.htpasswd nagiosadmin
htpasswd /etc/apache2/admin-users.htpasswd nmaapi
exit
```

### Confirm passwords

No login required (same realm as Solr)
* https://data.nma.gov.au/fuseki/
* https://data.nma.gov.au/signup/internal/
* https://data.nma.gov.au/usage.html

