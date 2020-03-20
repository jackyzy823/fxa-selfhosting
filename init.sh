set -a
[ -f .env ] && . .env || (echo "Cannot Found .env" && exit -1)
set +a
echo "Please ensure that you configured subdomains and their certs: www.$DOMAIN_NAME profile.$DOMAIN_NAME api.$DOMAIN_NAME token.$DOMAIN_NAME"
# do this to ensure .env 's   PERSISTENCEPATH  relate to docker-compose.yml
[ -f docker-compose.yml ] || (echo "Please run under the folder contains docker-compose.yml" && exit -1)
echo "make folder $PERSISTENCEPATH/public and set it all writalbe for profile avatar"
mkdir -p $PERSISTENCEPATH/public && chmod a+w $PERSISTENCEPATH/public
echo "make folder $PERSISTENCEPATH/mysql_data for mysql"
mkdir -p $PERSISTENCEPATH/mysql_data 

#download wait
if [ ! -f wait ] ;then 
	echo "Downloading docker-compose-wait from https://github.com/ufoscout/docker-compose-wait"
	if [ -x "$(command -v wget)" ]; then
		wget -O wait https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait || (echo "Download docker-compose-wait failed!" && exit -1)
	elif [ -x "$(command -v curl)" ]; then
		curl -o wait https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait || (echo "Download docker-compose-wait failed!" && exit -1)
	else
		echo "Cannot Download " 
		exit -1
	fi
fi

chmod +x wait

