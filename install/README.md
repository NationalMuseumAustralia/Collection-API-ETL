# NMA API server initialisation

Installs and configures software for the NMA API on a bare Ubuntu server.  

## Usage

Notes
* Add the appropriate server name after `./install.sh` below before execution
* The `apt upgrade` step may require manual input

```sh
sudo su -
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

NB: If the script stalls, you may need to kill any 'apt' processes before re-running:
```sh
ps -aux | grep 'apt'
sudo kill -9 <process-id>
sudo rm /var/cache/apt/archives/lock
```

Setting passwords

```sh
sudo su -
/usr/share/webmin/changepass.pl /etc/webmin root ####
htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin ####
exit
```
