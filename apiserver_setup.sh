#!/bin/bash

### Assumes: Ubuntu 16 or 18
### Instructions: 
###       Variable: gitserver - change to to github or gitlab cloning url
###       Variable: app_setup - if there's a setup shell script; otherwise pip install -r requirements.txt is run
###       Variable: senha     - default password for user apiserver (but password login will be disabled)
###       Variable: ip_addr   - Ip address or domain

gitserver="git@gitlab.com:caixa-preta-koort/suggest.git" # change this
app_setup="app_setup.sh"
ip_addr="67.205.143.152"

cd /home/apiserver/
echo From now on assuming logged as $(whoami) $(pwd)


# public key
mkdir .ssh
echo Copiando chave pública
chmod 700 .ssh
sudo cat /root/.ssh/authorized_keys  >> /home/apiserver/.ssh/authorized_keys
chmod 600 .ssh/authorized_keys

echo Create Python environment
sudo apt update
sudo apt install python3-venv python3-pip
python3 -m venv apiserver
source apiserver/bin/activate
pip install wheel
pip install gunicorn
pip install fastapi[all]
pip install uvicorn[all]

#private key
echo INSTRUCTION: Copy/paste the following public key to github/gitlab
ssh-keygen -q
cat .ssh/id_rsa.pub|less
echo Pull from git
git init
echo apiserver_setup.sh >> .gitignore
git remote add origin $gitserver
git fetch --all --prune
git checkout master
git pull origin master

if [ -e $app_setup ]; then
   source $app_setup
 fi
pip install -r requirements.txt

echo Initial nginx install
sudo apt update
sudo apt install nginx
sudo ufw allow 'Nginx HTTP'
sudo systemctl status nginx --no-pager

echo Set up systemd service
cat > apiserver.service <<- EOM
[Unit]
Description=Gunicorn instance to serve apiserver
After=network.target

[Service]
User=apiserver
Group=www-data
WorkingDirectory=/home/apiserver/
Environment="PATH=/home/apiserver/apiserver/bin"
ExecStart=/home/apiserver/apiserver/bin/gunicorn app:app -w 3 -k uvicorn.workers.UvicornWorker --bind unix:apiserver.sock -m 007
[Install]
WantedBy=multi-user.target
EOM

sudo mv apiserver.service  /etc/systemd/system/apiserver.service
echo Stat service
sudo systemctl start apiserver
echo Enable service
sudo systemctl enable apiserver
echo Service status
sudo systemctl status apiserver --no-pager

echo Set up nginx for gunicorn 
sudo ufw allow 'Nginx HTTP'
cat > apiserver.nginx <<- EOM
server {
    listen 8000;
    server_name $ip_addr;
    location / {
            include proxy_params;
            proxy_pass http://unix:/home/apiserver/apiserver.sock;
                }
	}
EOM
sudo cp apiserver.nginx /etc/nginx/sites-available/apiserver
sudo nginx -t 
sudo ufw allow 'Nginx Full'


sudo systemctl daemon-reload
sudo systemctl stop apiserver 
sudo systemctl start apiserver 
sudo systemctl status apiserver --no-pager

