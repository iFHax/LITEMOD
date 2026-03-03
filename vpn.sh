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
FILE="https://raw.githubusercontent.com/sipitongyo/resources/main/service"


# ==================================================
#  VPN Installer by VPN Legasi
# ==================================================

export DEBIAN_FRONTEND=noninteractive
OS=$(uname -m)
MYIP2="s/xxxxxxxxx/$MYIP/g"
ANU=$(ip -o -4 route show to default | awk '{print $5}')

# ==================================================
#  Install OpenVPN & Easy-RSA
# ==================================================
apt update -y
apt install -y openvpn easy-rsa unzip iptables-persistent

mkdir -p /etc/openvpn/server/easy-rsa/
cd /etc/openvpn/
wget ${FILE}/vpn.zip
unzip vpn.zip && rm -f vpn.zip
chown -R root:root /etc/openvpn/server/easy-rsa/

# Plugin PAM auth
mkdir -p /usr/lib/openvpn/
cp /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so \
   /usr/lib/openvpn/openvpn-plugin-auth-pam.so

# Auto start OpenVPN
sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn

# Aktifkan service
systemctl enable --now openvpn-server@server-tcp-1194
systemctl enable --now openvpn-server@server-udp-2200
systemctl enable --now openvpn-server@server-tcp-ssl

# IPv4 forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# ==================================================
#  Generate Client Config (3 Jenis)
# ==================================================
make_client_conf() {
    local FILE=$1
    local PROTO=$2
    local PORT=$3
    local USE_PROXY=$4

    cat > /etc/openvpn/${FILE}.ovpn <<-EOF
setenv FRIENDLY_NAME "OVPN VPN LEGASI"
setenv CLIENT_CERT 0
client
dev tun
proto ${PROTO}
remote xxxxxxxxx ${PORT}
$( [ "$USE_PROXY" = "yes" ] && echo "http-proxy xxxxxxxxx 8000
http-proxy-option CUSTOM-HEADER X-Forwarded-Host domain.com" )
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
<ca>
$(cat /etc/openvpn/server/ca.crt)
</ca>
EOF

    sed -i "$MYIP2" /etc/openvpn/${FILE}.ovpn
    cp /etc/openvpn/${FILE}.ovpn /home/vps/public_html/${FILE}.ovpn
    echo -e "${green}Generated ${FILE}.ovpn${NC}"
}

# Generate configs
make_client_conf client-tcp-1194 tcp 1194 yes
make_client_conf client-udp-2200 udp 2200
make_client_conf client-tcp-ssl tcp 442 yes

# ==================================================
#  Firewall Rules
# ==================================================
iptables -t nat -I POSTROUTING -s 10.6.0.0/24 -o $ANU -j MASQUERADE
iptables -t nat -I POSTROUTING -s 10.7.0.0/24 -o $ANU -j MASQUERADE
iptables-save > /etc/iptables.up.rules
iptables-restore < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

# Restart OpenVPN
systemctl restart openvpn

# Bersihkan
history -c
rm -f /root/vpn.sh
