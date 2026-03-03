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

export IP=$(curl -s https://ipinfo.io/ip/)

# Function check status
check_status() {
    if systemctl is-active --quiet "$1"; then
        echo -e "${GREEN}Running${NC}"
    else
        echo -e "${RED}Error${NC}"
    fi
}

# Array semua services
services=("ssh" "dropbear" "stunnel4" "squid" "nginx" "ws-stunnel" "xray")
declare -A status

# Loop dan check
for s in "${services[@]}"; do
    status["$s"]=$(check_status "$s")
done

# Output
clear
echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "\E[44;1;39m     STATUS SERVICE INFORMATION     \E[0m"
echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "Server Uptime        : $(uptime -p | cut -d ' ' -f2-)"
echo -e "Current Time         : $(date '+%d-%m-%Y %X')"
echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "    $PURPLE Service        :  Status$NC"
echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "OpenSSH             : ${status[ssh]}"
echo -e "Dropbear            : ${status[dropbear]}"
echo -e "Stunnel5            : ${status[stunnel4]}"
echo -e "Squid               : ${status[squid]}"
echo -e "NGINX               : ${status[nginx]}"
echo -e "SSH NonTLS          : ${status[ws-stunnel]}"
echo -e "SSH TLS             : ${status[ws-stunnel]}"
echo -e "Xray                : ${status[xray]}"
