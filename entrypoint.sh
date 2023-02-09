#!/bin/bash
apt update && apt install -y wget unzip
nx=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 4)
xpid=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 8)
[ -n "${ver}" ] && wget -O $nx.zip https://github.com/XTLS/Xray-core/releases/download/v${ver}/Xray-linux-64.zip
[ ! -s $nx.zip ] && wget -O $nx.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip $nx.zip xray && rm -f $nx.zip
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
chmod a+x xray && mv xray $xpid
sed -i "s/uuid/$uuid/g" ./config.json
# sed -i "s/uuid/$uuid/g" /etc/nginx/nginx.conf
[ -n "${www}" ] && rm -rf /usr/share/nginx/* && wget -c -P /usr/share/nginx "https://github.com/zhiufwer/dp-zh/raw/main/3w/html${www}.zip" && unzip -o "/usr/share/nginx/html${www}.zip" -d /usr/share/nginx/html
cat config.json | base64 > config
rm -f config.json

# argo与加密方案出自fscarmen
rm -f cloudflared-linux-amd64*
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared-linux-amd64
./cloudflared-linux-amd64 tunnel --url http://localhost:8080 --no-autoupdate > argo.log 2>&1 &
sleep 5
ARGO=$(cat argo.log | grep -oE "https://.*[a-z]+cloudflare.com" | sed "s#https://##")
# xver=`./$xpid version | sed -n 1p | awk '{print $2}'`
# UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
# v4=$(curl -s4m6 ip.sb -k)
# v4l=`curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"'`

Argo_xray_vmess="vmess://$(echo -n "\
{\
\"v\": \"2\",\
\"ps\": \"Argo_xray_vmess\",\
\"add\": \"${ARGO}\",\
\"port\": \"443\",\
\"id\": \"$uuid\",\
\"aid\": \"0\",\
\"net\": \"ws\",\
\"type\": \"none\",\
\"host\": \"${ARGO}\",\
\"path\": \"/$uuid-vm\",\
\"tls\": \"tls\",\
\"sni\": \"${ARGO}\"\
}"\
    | base64 -w 0)" 
Argo_xray_vless="vless://${uuid}@${ARGO}:443?encryption=none&security=tls&sni=$ARGO&type=ws&host=${ARGO}&path=/$uuid-vl#Argo_xray_vless"
Argo_xray_trojan="trojan://${uuid}@${ARGO}:443?security=tls&type=ws&host=${ARGO}&path=/$uuid-tr&sni=$ARGO#Argo_xray_trojan"

cat > log << EOF
****************************************************************

================================================================
----------------------------------------------------------------
1：Vmess+ws+tls配置明文如下，相关参数可复制到客户端
Argo服务器临时地址（可更改为CDN自选IP）：$ARGO
https端口：可选443、2053、2083、2087、2096、8443，tls必须开启

uuid：$uuid
传输协议：ws
host/sni：$ARGO
path路径：/$uuid-vm

分享链接如下（默认443端口、tls开启，服务器地址可更改为自选IP）
${Argo_xray_vmess}
----------------------------------------------------------------

${Argo_xray_vless}
----------------------------------------------------------------

${Argo_xray_trojan}

****************************************************************
EOF
 


cat log
nginx
base64 -d config > config.json; ./$xpid -config=config.json
