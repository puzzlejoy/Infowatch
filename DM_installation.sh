#! /bin/bash

# Sources list
echo "Sourcelist update"
astraVersion=$(cat /etc/astra_version)
echo "deb http://dl.astralinux.ru/astra/frozen/1.7_x86-64/$astraVersion/repository-base/ 1.7_x86-64 main contrib non-free" > /etc/apt/sources.list
echo "deb http://dl.astralinux.ru/astra/frozen/1.7_x86-64/$astraVersion/repository-extended/ 1.7_x86-64 contrib main non-free " >> /etc/apt/sources.list
echo "deb http://dl.astralinux.ru/astra/frozen/1.7_x86-64/$astraVersion/repository-main/ 1.7_x86-64 main contrib non-free" >> /etc/apt/sources.list
apt update
echo "Done!"

# Addition to AD 
apt-get install fly-admin-ad-client -y
apt update
fly-admin-ad-client

# /etc/hosts change
echo "Working with the /etc/hosts file..."
echo "Enter domain: "; read ADdomain
urIP=$(ifconfig eth0 | awk '/inet / {split($2, a, ":"); print a[1]}')
hostname=$(hostname)
newEntry="$urIP $hostname.$ADdomain $hostname"
sed -i "2s/.*/$newEntry/" /etc/hosts
echo "Done!"

# SSH
systemctl start ssh && systemctl enable ssh
echo "The SSH service will be start and added to autostart"

# .NET 6 Installation 
"Installing .NET, socat and conntrack..."
apt install ca-certificates apt-transport-https -y
wget -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null 
wget https://packages.microsoft.com/config/debian/10/prod.list -O /etc/apt/sources.list.d/microsoft-prod.list 
apt update 
apt install dotnet-sdk-6.0 aspnetcore-runtime-6.0 -y
apt install conntrack -y
apt install socat -y
echo "Success!"

# PostgreSQL installation
echo "Installation PostgreSQL"
apt-get install postgresql -y
read -p "Enter PostgreSQL Password: " postgrePass
sudo -u postgres 
psql -c "alter user postgres with password '$postgrePass'"
exit
echo "PostgreSQL is Done, password is $postgrePass!"

# Sorting IWDM files
echo "Moving IWDM-installer files..."
echo "Enter .zip archive file name"; read zipFolder
mkdir IWDM/
unzip -j $zipFolder;
mv i* IWDM/
cd IWDM/
echo "Done!"

# Platform Installation
echo "Platform IWDM installation..."
tar xvf iw_devicemonitor_setup*
./setup.py install
kubectl get pods -n infowatch 
kubectl get configmap nginx-config -o yaml -n infowatch > n.yaml
nano n.yaml
kubectl apply -f n.yaml
kubectl rollout restart deployment webgui-central -n infowatch

# DM Server installation 
chmod +x ./install.sh
bash install.sh 

# Certificates check
read -p "Enter the IP address of the server where you want to copy the file " serverIP
read -p "Enter the username of the server where you want to copy the file " serverUser
scp $serverUser@$serverIP:/opt/iw/tm5/etc/cert/trusted_certificates/ /home/iwdm/tmca.crt
mv tmca.crt /usr/local/share/ca-certificates/tmca.crt
update-ca-certificates

# dont forget to install the IWTM web-server cert, 'cause this is done manually

# EPEVENTS cert
kubectl get secret -n infowatch epeventskeys-central -o 'go-template={{index .data "tls.crt"}}' | base64 -d > plca.crt
mv plca.crt /usr/share/ca-certificates/
update-ca-certificates

# 



