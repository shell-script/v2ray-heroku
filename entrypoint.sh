#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

######################################################
# Anything wrong? Contact me via telegram: @CN_SZTL. #
######################################################

if [[ -z "${AppName}" ]]; then
  AppName="no"
fi

if [[ -z "${Level}" ]]; then
  Level="1"
fi

if [[ -z "${UUID}" ]]; then
  if [ "$AppName" = "no" ]; then 
    UUID="4890bd47-5180-4b1c-9a5d-3ef686543112"
  else
    UUID="$(uuid)"
  fi
fi

if [[ -z "${AlterID}" ]]; then
  AlterID="10"
fi

if [[ -z "${V2_Path}" ]]; then
  V2_Path="/shellscript"
fi

if [[ -z "${V2_QR_Path}" ]]; then
  V2_QR_Code="subscription"
fi

rm -f "/etc/localtime"
cp "/usr/share/zoneinfo/Asia/Shanghai" "/etc/localtime"

System_bit="$(getconf LONG_BIT)"
[[ "${System_bit}" == "32" ]] && dl_version="386"
[[ "${System_bit}" == "64" ]] && dl_version="amd64"

if [ "$VER" = "latest" ]; then
  v2ray_version="$(wget -qO- "https://api.github.com/repos/v2ray/v2ray-core/releases/latest" | grep "tag_name" | cut -d\" -f4)"
else
  v2ray_version="v$VER"
fi

mkdir "/v2raybin"
cd "/v2raybin"
wget -qO "v2ray.zip" "https://github.com/v2ray/v2ray-core/releases/download/${v2ray_version}/v2ray-linux-${System_bit}.zip"
unzip "v2ray.zip"
rm -f "v2ray.zip"
chmod +x "/v2raybin/v2ray-${v2ray_version}-linux-${System_bit}/*"

mkdir "/caddybin"
cd "/caddybin"
wget -qO "caddy.tar.gz" "https://caddyserver.com/download/linux/${dl_version}?plugins=http.forwardproxy&license=personal"
tar xvf "caddy.tar.gz"
rm -f "caddy.tar.gz"
chmod +x "caddy"
cd "/root"
mkdir "/wwwroot"
cd "/wwwroot"

wget -qO "demo.tar.gz" "https://github.com/shell-script/v2ray-heroku/raw/master/demo.tar.gz"
tar xvf "demo.tar.gz"
rm -f "demo.tar.gz"

cat <<-EOF > "/v2raybin/v2ray-${v2ray_version}-linux-${System_bit}/config.json"
{
    "log":{
        "loglevel":"warning"
    },
    "inbound":{
        "protocol":"vmess",
        "listen":"127.0.0.1",
        "port":10000,
        "settings":{
            "clients":[
                {
                    "id":"${UUID}",
                    "level":"${Level}",
                    "alterId":"${AlterID}"
                }
            ]
        },
        "streamSettings":{
            "network":"ws",
            "wsSettings":{
                "path":"${V2_Path}"
            }
        }
    },
    "outbound":{
        "protocol":"freedom",
        "settings":{
        }
    }
}
EOF

cat <<-EOF > "/caddybin/Caddyfile"
http://0.0.0.0:${PORT}
{
  root /wwwroot
  index index.html index.txt
  timeouts none
  proxy ${V2_Path} localhost:10000 {
    websocket
    header_upstream -Origin
  }
}
EOF

cat <<-EOF > "/v2raybin/vmess.json"
{
    "v": "2",
    "ps": "${AppName}.herokuapp.com",
    "add": "${AppName}.herokuapp.com",
    "port": "443",
    "id": "${UUID}",
    "aid": "${AlterID}",			
    "net": "ws",			
    "type": "none",			
    "host": "",			
    "path": "${V2_Path}",	
    "tls": "tls"			
}
EOF

if [ "$AppName" = "no" ]; then
  rm -f "/v2raybin/vmess.json"
else
  mkdir "/wwwroot/${V2_QR_Path}"
  vmess="vmess://$(cat /v2raybin/vmess.json | base64 -w 0)" 
  Linkbase64="$(echo -n "${vmess}" | tr -d "\n" | base64 -w 0) "
  echo "${Linkbase64}" | tr -d "\n" > "/wwwroot/${V2_QR_Path}/index.txt"
  echo -n "${vmess}" | qrencode -s 6 -o "/wwwroot/${V2_QR_Path}/qrcode.png"
fi

cd "/v2raybin/v2ray-${v2ray_version}-linux-${System_bit}"
./v2ray &
cd "/caddybin"
./caddy -conf="Caddyfile"