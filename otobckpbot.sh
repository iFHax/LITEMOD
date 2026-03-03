#!/bin/bash

# Warna
DF='\e[39m'
Bold='\e[1m'
Blink='\e[5m'
yell='\e[33m'
red='\e[31m'
green='\e[32m'
blue='\e[34m'
PURPLE='\e[35m'
CYAN='\e[36m'
Lred='\e[91m'
Lgreen='\e[92m'
Lyellow='\e[93m'
NC='\e[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
LIGHT='\033[0;37m'

# Variabel
owner="sipitongyo"
gitlink="https://raw.githubusercontent.com"

IP=$MYIP
date=$(date +"%Y-%m-%d")
token=$(cat /etc/token_bott | awk '{print $2}')
admin=$(cat /etc/admin_id | awk '{print $2}')
InputPass=123
rm -rf /root/backup
mkdir -p /root/backup
cp /etc/passwd backup/
cp /etc/group backup/
cp /etc/shadow backup/
cp /etc/gshadow backup/
cp -r /etc/wireguard backup/wireguard
cp -r /usr/local/etc/xray backup/xray/
cd /root
zip -rP $InputPass $IP-$Name-$date.zip backup >/dev/null 2>&1
curl --request POST \
  --url https://api.telegram.org/bot$token/sendDocument?chat_id=$admin \
  --header 'content-type: multipart/form-data' \
  --form document=@/root/$IP-$Name-$date.zip \
  --form 'caption=Here Is Your Backup Files'
clear
rm -rf backup
