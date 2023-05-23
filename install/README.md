# NMA API server initialisation

Installs and configures software for the NMA API on a bare Ubuntu server.  

### Data directories

The install script creates a stub root directory `/mnt`. This should be attached
to the appropriate data share (one each for `test` or `production`).

The share directory should contain sub-directories:
* `./emu_data/full`
* `./emu_data/incremental`
* `./dams_data`

The install script will create the ETL logging sub-directory:
* `./emu_data/etl`

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

### Set passwords

Key in appropriate passwords when prompted

```sh
sudo su -
touch /etc/apache2/admin-users.htpasswd
htpasswd /etc/apache2/admin-users.htpasswd admin
htpasswd /etc/apache2/admin-users.htpasswd nmaapi
exit
```

### Confirm passwords

Login as `admin`
* https://data.nma.gov.au/solr/ 

No login required (same realm as Solr)
* https://data.nma.gov.au/fuseki/
* https://data.nma.gov.au/signup/internal/
* https://data.nma.gov.au/usage.html
