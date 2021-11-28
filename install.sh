#!/bin/bash

# usage:
# bash install.sh
# bash install.sh [uuid]

if [ ! -n "$1" ] ;then
	uid=$(uuidgen)
else 
	if [[ "$1" =~ ^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$ ]]; then 
		echo "uid is ok" 
		uid=$1
	else
		echo "uid is error"
		exit 1
	fi
fi

cp ./origin/config.json ./config.json

sed -i -r "s/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/$uid/" config.json
if [[ $(command -v docker) ]]; 
then
	echo "docker is installed.."
else
        echo "Let's get docker"
        curl -fsSL https://get.docker.com -o get-docker.sh
        bash get-docker.sh
fi

if [[ $(command -v docker-compose) ]]; 
then
	echo "docker-compose is installed.."
else
        echo "Let's get docker-compose"
        sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi
systemctl start docker
docker-compose up -d --force-recreate

sleep 2


httpsurl=$(docker-compose logs cloudflared | grep -oE "https://.*trycloudflare.com" | tail -n 1)
cloudflareurl=${httpsurl:8}
basestr=$(echo "{\"add\":\"${cloudflareurl}\",\"aid\":0,\"host\":\"\",\"id\":\"${uid}\",\"net\":\"ws\",\"path\":\"/\",\"port\":443,\"ps\":\"${cloudflareurl}\",\"tls\":\"tls\",\"type\":\"none\",\"v\":2}" | base64 -w0)
echo "vmess://${basestr}"
echo "For qrcode: https://cyberchef.eu.org/#recipe=Generate_QR_Code('SVG',2,0,'Low')&input="$(echo vmess://${basestr} | base64 -w0 | tr -d "=")
