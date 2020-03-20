set -a
[ -f .env ] && . .env || (echo "Cannot Found .env" && exit -1)
set +a
# do this to ensure .env 's   PERSISTENCEPATH  relate to docker-compose.yml
[ -f docker-compose.yml ] || (echo "Please run under the folder contains docker-compose.yml" && exit -1)
mkdir -p $PERSISTENCEPATH/public && chmod a+w $PERSISTENCEPATH/public
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

