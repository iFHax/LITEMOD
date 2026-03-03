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

# Warna
green() { echo -e "\033[32;1m$*\033[0m"; }
red() { echo -e "\033[31;1m$*\033[0m"; }
NC='\033[0m'

echo -e "[ ${green}INFO${NC} ] Web Socket XRAY Core Vless & gRPC"
sleep 3

date
echo ""

sleep 1
mkdir -p /etc/xray

echo -e "[ ${green}INFO${NC} ] Updating package lists..."
apt update -y

echo -e "[ ${green}INFO${NC} ] Installing dependencies..."
apt install -y iptables iptables-persistent curl socat xz-utils wget apt-transport-https gnupg2 dnsutils lsb-release \
    cron bash-completion ntpdate chrony zip pwgen openssl netcat-openbsd

echo -e "[ ${green}INFO${NC} ] Setting time synchronization..."
# Force sync time once
ntpdate pool.ntp.org || echo "ntpdate failed, skipping initial sync"
# Enable automatic NTP via chrony/timedatectl
timedatectl set-ntp true

echo -e "[ ${green}INFO${NC} ] Enable and restart chrony service..."
systemctl enable chrony
systemctl restart chrony
# Force immediate sync
chronyc makestep

echo -e "[ ${green}INFO${NC} ] Set timezone..."
timedatectl set-timezone Asia/Kuala_Lumpur

echo -e "[ ${green}INFO${NC} ] Show chrony status..."
chronyc sourcestats -v
chronyc tracking -v

# Setup xray log folders & files
echo -e "[ ${green}INFO${NC} ] Setting up Xray log directories and permissions..."
domainSock_dir="/run/xray"
mkdir -p "$domainSock_dir"
chown www-data:www-data "$domainSock_dir"

mkdir -p /var/log/xray /etc/xray
chown www-data:www-data /var/log/xray
chmod +x /var/log/xray

touch /var/log/xray/access.log
touch /var/log/xray/error.log

# Install Xray Core latest stable (v1.5.6)
echo -e "[ ${green}INFO${NC} ] Downloading & Installing xray core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version 25.10.15

# Setup ACME certificate with acme.sh
echo -e "[ ${green}INFO${NC} ] Setup ACME SSL certificate..."
systemctl stop nginx 2>/dev/null

mkdir -p /root/.acme.sh
curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh

/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt

/root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256
/root/.acme.sh/acme.sh --installcert -d "$domain" \
    --fullchainpath /etc/xray/xray.crt \
    --keypath /etc/xray/xray.key --ecc

chown -R nobody:nogroup /etc/xray
chmod 644 /etc/xray/xray.key
chmod 644 /etc/xray/xray.crt

# Setup cron job to renew SSL cert for nginx
#!/bin/bash
/etc/init.d/nginx stop
"/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" &> /root/renew_ssl.log
/etc/init.d/nginx start
' > /usr/local/bin/ssl_renew.sh
chmod +x /usr/local/bin/ssl_renew.sh

if ! crontab -l | grep -q 'ssl_renew.sh'; then
    (crontab -l 2>/dev/null; echo "15 03 */3 * * /usr/local/bin/ssl_renew.sh") | crontab -
fi

echo -e "[ ${green}INFO${NC} ] Setup completed."

#clean config
rm /usr/local/etc/xray/*.json

# set uuid
uuid=$(cat /proc/sys/kernel/random/uuid)

#Vless Json
cat > /usr/local/etc/xray/vless.json <<END
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    },
    {
      "listen": "127.0.0.1",
      "port": "14016",
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "$uuid"
#vless
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    },
    {
      "listen": "127.0.0.1",
      "port": "14017",
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "$uuid"
#vlessgrpc
          }
        ]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "vless-grpc"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    },
    {
      "listen": "127.0.0.1",
      "port": "14018",
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "$uuid"
#vless
          }
        ]
      },
      "streamSettings": {
        "network": "httpupgrade",
        "security": "none",
        "httpupgradeSettings": {
          "path": "/httpupgrade",
          "acceptProxyProtocol": false
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": ["api"],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": ["bittorrent"]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": ["StatsService"],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink": true,
      "statsOutboundDownlink": true
    }
  }
}
END

rm -rf /etc/systemd/system/xray*
cat> /etc/systemd/system/xray.service << END
[Unit]
Description=XRAY-Websocket Service  By VPN Legasi
Documentation=${host}
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/vless.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

END

cat> /etc/systemd/system/xray@.service << END
[Unit]
Description=XRAY-Websocket By VPN Legasi
Documentation=${host}
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/%i.json
Restart=on-failure
RestartPreventExitStatus=42
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

END

cat > /etc/systemd/system/runn.service <<EOF
[Unit]
Description=Multiport-Websocket Service By VPN Legasi
Documentation=${host}
After=network.target

[Service]
Type=simple
ExecStartPre=-/usr/bin/mkdir -p /var/run/xray
ExecStart=/usr/bin/chown www-data:www-data /var/run/xray
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
# // Iptable xray
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 14016 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 14017 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 14018 -j ACCEPT

# // Iptable xray
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 14016 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 14017 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 14018 -j ACCEPT

iptables-save >/etc/iptables.rules.v4
netfilter-persistent save
netfilter-persistent reload

# // Starting
systemctl daemon-reload
systemctl restart xray
systemctl enable xray
systemctl restart xray.service
systemctl enable xray.service

#nginx config
cat >/etc/nginx/conf.d/xray.conf <<EOF
    server {
             listen 80;
             listen [::]:80;
             listen 8080;
             listen [::]:8080;
             listen 443 ssl http2 reuseport;
             listen [::]:443 ssl http2 reuseport;
             server_name sock.vpnlegasi.com;
             ssl_certificate /etc/xray/xray.crt;
             ssl_certificate_key /etc/xray/xray.key;
             ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
             ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
             root /home/vps/public_html;

             location / {
                       proxy_http_version 1.1;
                       proxy_set_header Host ccc;
             proxy_set_header X-Real-IP aaa;
             proxy_set_header X-Forwarded-For bbb;
             proxy_set_header Upgrade ddd;
             proxy_set_header Connection "upgrade";

             if (ddd = "websocket") {
                rewrite ^.*$ / break;
                proxy_pass http://127.0.0.1:14016;
                break;
             }

             proxy_pass http://127.0.0.1:700;
 }
             location ~* httpupgrade {
                       rewrite ^.*httpupgrade.*$ /httpupgrade break;
                       proxy_redirect off;
                       proxy_pass http://127.0.0.1:14018;
                       proxy_http_version 1.1;
             proxy_set_header X-Real-IP aaa;
             proxy_set_header X-Forwarded-For bbb;
             proxy_set_header Upgrade ddd;
             proxy_set_header Connection "upgrade";
             proxy_set_header Host eee;
 }
             location ^~ /vless-grpc {
                      proxy_redirect off;
                      grpc_set_header X-Real-IP aaa;
                      grpc_set_header X-Forwarded-For bbb;
             grpc_set_header Host eee;
             grpc_pass grpc://127.0.0.1:14017;
 }
        }
EOF

# // Move
sed -i 's/aaa/$remote_addr/g' /etc/nginx/conf.d/xray.conf
sed -i 's/bbb/$proxy_add_x_forwarded_for/g' /etc/nginx/conf.d/xray.conf
sed -i 's/ccc/$host/g' /etc/nginx/conf.d/xray.conf
sed -i 's/ddd/$http_upgrade/g' /etc/nginx/conf.d/xray.conf
sed -i 's/eee/$http_host/g' /etc/nginx/conf.d/xray.conf
sed -i 's/fff/"upgrade"/g' /etc/nginx/conf.d/xray.conf
sed -i 's/ggg/"websocket"/g' /etc/nginx/conf.d/xray.conf

systemctl stop nginx
rm -rf /lib/systemd/system/nginx.service
#custom nginx

echo -e "$yell[SERVICE]$NC Restart All service"

systemctl stop nginx

if [ -f /lib/systemd/system/nginx.service ]; then
    mv /lib/systemd/system/nginx.service /lib/systemd/system/nginx.service.bak-$(date +%F-%T)
fi

cat > /lib/systemd/system/nginx.service <<EOF
[Unit]
Description=High performance web server and a reverse proxy server by VPN Legasi
Documentation=${host}
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry=5 --pidfile /run/nginx.pid
ExecStartPost=/bin/sleep 1
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

sleep 1

systemctl daemon-reload

echo -e "[ ${green}ok${NC} ] Enable & restart Xray"
systemctl enable xray
systemctl restart xray
sleep 1

echo -e "[ ${green}ok${NC} ] Enable & restart Nginx"
systemctl enable nginx
systemctl restart nginx
sleep 1

rm -rf /etc/log-create-user.log
sleep 1

clear
