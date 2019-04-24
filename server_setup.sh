#!/bin/bash

### Assumes: Ubuntu 18
### Instructions: 
###       Variable: gitserver - change to to github or gitlab cloning url
###       Variable: app_setup - if there's a setup shell script; otherwise pip install -r requirements.txt is run
###       Variable: senha     - default password for user apiserver (but password login will be disabled)

gitserver="gitserver" # change this
app_setup="app_setup.sh" # it's okay if this doesn't exist
senha="esta_senha"



# criar usuário
if [ `id -u apiserver 2>/dev/null || echo -1` -ge 0 ]; then 
    echo User apiserver found
else
    echo Assumindo root
    mkdir -p /home/apiserver/.ssh
    touch /home/apiserver/.ssh/authorized_keys
    echo Digite a senha
    adduser apiserver --ingroup www-data --disabled-password --quiet --home /home/apiserver/
    echo $senha | chpasswd
    usermod -aG sudo apiserver
    su apiserver
fi

echo From now on assuming logged as apiserver
# public key
echo Copiando chave pública
chmod 700 .ssh
sudo cat /root/.ssh/authorized_keys  >> .ssh/authorized_keys
chmod 600 authorized_keys
exit



echo Create Python environment
python3 -m venv apiserver
source apiserver/bin/activate
pip install gunicorn
pip install fastapi[all]
pip install uvicorn[all]

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

[Service]User=apiserver {
    listen 8000;
    server_name 142.93.116.203;
    location / {
            include proxy_params;
            proxy_pass http://unix:/home/apiserver/apiserver.sock;
                }
}
server
Group=www-data
WorkingDirectory=/home/apiserver/
Environment="PATH=/home/apiserver/apiserver/bin"
ExecStart=/home/apiserver/apiserver/bin/gunicorn app:app -w 3 -k uvicorn.workers.UvicornWorker --bind unix:apiserver.sock -m 007
[Install]
WantedBy=multi-user.target
EOM
mv apiserver.service > /etc/systemd/system/ 
sudo systemctl start apiserver; sudo systemctl enable apiserver
sudo systemctl status apiserver --no-pager

echo Set up nginx for gunicorn 
cat > apiserver <<- EOM
server {
    listen 8000;
    server_name 142.93.116.203;
    location / {
            include proxy_params;
            proxy_pass http://unix:/home/apiserver/apiserver.sock;
                }
}
EOM
mv apiserver /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/apiserver /etc/nginx/sites-enabled
sudo nginx -t
sudo ufw allow 'Nginx Full'

echo Pull from git
git init
git remote add master $gitserver
git pull origin master 

if [ -e x.txt ]
then
    source $app_setup

else
    pip install -r requirements.txt 
fi

sudo systemctl stop apiserver 
sudo systemctl start apiserver 
sudo systemctl status apiserver --no-pager
