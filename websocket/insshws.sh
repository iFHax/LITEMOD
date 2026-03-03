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
rm -f -- "$0"

# Variabel
HOST="https://raw.githubusercontent.com/iFHax/LITEMOD/main"

set -e
cd

# ==================================================
#  Install Script WebSocket-SSH Python
# ==================================================
echo "[INFO] Memasang skrip WebSocket..."

wget -O /usr/local/bin/ws-openssh "${HOST}/websocket/openssh-socket.py"
wget -O /usr/local/bin/ws-dropbear "${HOST}/websocket/dropbear-ws.py"
wget -O /usr/local/bin/ws-stunnel "${HOST}/websocket/ws-stunnel"

chmod +x /usr/local/bin/ws-openssh
chmod +x /usr/local/bin/ws-dropbear
chmod +x /usr/local/bin/ws-stunnel

# ==================================================
#  Install Systemd Services
# ==================================================
echo "[INFO] Memasang service systemd..."

wget -O /etc/systemd/system/ws-dropbear.service "${HOST}/websocket/service-wsdropbear"
wget -O /etc/systemd/system/ws-stunnel.service "${HOST}/websocket/ws-stunnel.service"

chmod +x /etc/systemd/system/ws-dropbear.service
chmod +x /etc/systemd/system/ws-stunnel.service

# ==================================================
#  Enable & Restart Services
# ==================================================
systemctl daemon-reload

systemctl enable ws-dropbear.service
systemctl restart ws-dropbear.service

systemctl enable ws-stunnel.service
systemctl restart ws-stunnel.service

# ==================================================
#  Done
# ==================================================
echo "=============================================="
echo "✅ WebSocket Tunneling Installed"
echo "Service aktif  : ws-dropbear, ws-stunnel"
echo "=============================================="

rm -f inwebsocket.sh 2>/dev/null
