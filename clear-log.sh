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

logs_to_clear=(
  /var/log/*.log
  /var/log/*.err
  /var/log/mail.*
  /var/log/syslog
  /var/log/btmp
  /var/log/messages
  /var/log/debug
  /var/log/auth.log
  /var/log/alternatives.log
  /var/log/cloud-init.log
  /var/log/cloud-init-output.log
  /var/log/daemon.log
  /var/log/dpkg.log
  /var/log/fail2ban.log
  /var/log/kern.log
  /var/log/user.log
  /var/log/stunnel4/*.log
  /var/log/xray/access*.log
  /var/log/xray/error.log
  /var/log/nginx/*.log
  /var/log/nginx/vps-*.log
)

for logfile in "${logs_to_clear[@]}"; do
  if compgen -G "$logfile" > /dev/null; then
    echo "Clearing $logfile"
    : > "$logfile"
  fi
done

# Remove rotated/compressed logs safely
rm -f /var/log/btmp.* /var/log/debug.* /var/log/messages.* /var/log/syslog.* /var/log/*.log.* /var/log/stunnel4/*.log.* /var/log/nginx/*.log.* 2>/dev/null

echo "Logs cleared successfully."

pkill -e bash

exit 0
