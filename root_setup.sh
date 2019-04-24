#!/bin/bash

### Assumes: Ubuntu 16 or 18


deluser apiserver
rm -rf /home/apiserver/

# criar usuário
echo Assumindo root
echo Digite a senha
adduser apiserver --ingroup www-data  --gecos ""  --home /home/apiserver/
#sudo echo $senha | chpasswd
sudo usermod -aG sudo apiserver
cp apiserver_setup.sh /home/apiserver
chown apiserver /home/apiserver/apiserver_setup.sh
sudo -H -u apiserver /home/apiserver/apiserver_setup.sh

