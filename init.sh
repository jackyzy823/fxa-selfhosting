set -a
[ -f .env ] && . .env || (echo -e "\e[31mCannot Found .env\e[0m" && exit -1)
set +a
echo -e "\e[32mPlease ensure that you configured subdomains and their certs: www.$DOMAIN_NAME profile.$DOMAIN_NAME api.$DOMAIN_NAME token.$DOMAIN_NAME\e[0m"
# do this to ensure .env 's   PERSISTENCEPATH  relate to docker-compose.yml
[ -f docker-compose.yml ] || (echo "Please run under the folder contains docker-compose.yml" && exit -1)
echo -e "\e[32mmake folder $PERSISTENCEPATH/public and set it all writalbe for profile avatar\e[0m"
mkdir -p $PERSISTENCEPATH/public && chmod a+w $PERSISTENCEPATH/public
echo -e "\e[32mmake folder $PERSISTENCEPATH/mysql_data for mysql\e[0m"
mkdir -p $PERSISTENCEPATH/mysql_data 

#download wait
if [ ! -f wait ] ;then 
	echo -e "\e[32mDownloading docker-compose-wait from https://github.com/ufoscout/docker-compose-wait\e[0m"
	if [ -x "$(command -v wget)" ]; then
		wget -O wait https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait || (echo -e "\e[31mDownload docker-compose-wait failed!\e[0m" && exit -1)
	elif [ -x "$(command -v curl)" ]; then
		curl -o wait https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait || (echo -e "\e[31mDownload docker-compose-wait failed!\e[0m" && exit -1)
	else
		echo -e "\e[31mCannot Download docker-compose. Please manually download it.\e[0m" 
		exit -1
	fi
else
	echo ""
fi

chmod +x wait

