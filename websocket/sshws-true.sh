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
owner="sipitongyo"
gitlink="https://raw.githubusercontent.com"

# ==================================================
#  Start SSH WebSocket via tmux
# ==================================================

set -e

# ==================================================
#  Check & Install tmux
# ==================================================
if ! command -v tmux >/dev/null 2>&1; then
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq -o=Dpkg::Use-Pty=0 tmux >/dev/null 2>&1
fi

# ==================================================
#  Ambil Port dari log-install.txt
# ==================================================
LOG_FILE="/root/log-install.txt"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "[ERROR] $LOG_FILE tidak ditemui. Pastikan script install utama sudah dijalankan."
    exit 1
fi

# Dropbear ports
portdb=$(grep -w "Dropbear" "$LOG_FILE" | cut -d: -f2 | sed 's/ //g' | cut -f2 -d",")
portdb2=$(grep -w "Dropbear" "$LOG_FILE" | cut -d: -f2 | sed 's/ //g' | cut -f1 -d",")

# SSH WebSocket
portsshws=$(grep -w "SSH Websocket" "$LOG_FILE" | cut -d: -f2 | awk '{print $1}')

# SSH SSL WebSocket
wsssl=$(grep -w "SSH SSL Websocket" "$LOG_FILE" | cut -d: -f2 | awk '{print $1}')

echo "[INFO] Port Dropbear        : $portdb, $portdb2"
echo "[INFO] Port SSH WebSocket   : $portsshws"
echo "[INFO] Port SSH SSL WS      : $wsssl"

# ==================================================
#  Jalankan Node Proxy dalam tmux
# ==================================================
PROXY_JS="/usr/bin/proxy3.js"
if [[ ! -f "$PROXY_JS" ]]; then
    echo "[ERROR] $PROXY_JS tidak ditemui."
    exit 1
fi

# Pastikan session lama dimatikan dulu
tmux kill-session -t sshws >/dev/null 2>&1 || true
tmux kill-session -t sshwsssl >/dev/null 2>&1 || true

# Start session baru
echo "[INFO] Memulakan tmux session untuk SSH WS..."
tmux new-session -d -s sshws "node $PROXY_JS -dport $portdb -mport $portsshws -o /root/sshws.log"

echo "[INFO] Memulakan tmux session untuk SSH SSL WS..."
tmux new-session -d -s sshwsssl "node $PROXY_JS -dport $portdb -mport 700 -o /root/sshwsssl.log"

echo "=============================================="
echo "✅ SSH WS & SSH SSL WS telah dimulakan dalam tmux."
echo "   - Lihat log: cat /root/sshws.log /root/sshwsssl.log"
echo "   - Semak tmux session: tmux ls"
echo "=============================================="
