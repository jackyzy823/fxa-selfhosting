set -a
if [ -f .env ] && . .env ;then
	echo -e "\e[32mFound .env\e[0m"
else
	echo -e "\e[31mCannot Found .env\e[0m"
	exit -1
fi
set +a

echo -e "\e[32mPlease make sure that you configured subdomains and their certs: www.$DOMAIN_NAME profile.$DOMAIN_NAME token.$DOMAIN_NAME  api.$DOMAIN_NAME oauth.$DOMAIN_NAME (api.$DOMAIN_NAME and oauth.$DOMAIN_NAME must use same cert) \e[0m"
# do this to ensure .env 's   PERSISTENCEPATH  relate to docker-compose.yml
echo -e "\e[32mPlease make sure that 0.0.0.0:443 and 127.0.0.1:9001 is not used\e[0m"

if [ -f docker-compose.yml ] ;then
	:
else
	echo "Please run under the folder contains docker-compose.yml"
	exit -1
fi

echo -e "\e[32mmake folder $PERSISTENCEPATH/public and set it all writalbe for profile avatar\e[0m"
mkdir -p $PERSISTENCEPATH/public && chmod a+w $PERSISTENCEPATH/public
echo -e "\e[32mmake folder $PERSISTENCEPATH/mysql_data for mysql\e[0m"
mkdir -p $PERSISTENCEPATH/mysql_data 

#download wait
if [ ! -f wait ] ;then 
	echo -e "\e[32mDownloading docker-compose-wait from https://github.com/ufoscout/docker-compose-wait\e[0m"
	if [ -x "$(command -v wget)" ]; then
		if wget -O wait https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait ;then
			echo -e "\e[32mDownload docker-compose-wait successfully!\e[0m"
		else
			echo -e "\e[31mDownload docker-compose-wait failed!\e[0m"
			exit -1
		fi
	elif [ -x "$(command -v curl)" ]; then
		if curl -o wait https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait ;then
			echo -e "\e[32mDownload docker-compose-wait successfully!\e[0m"
		else
			echo -e "\e[31mDownload docker-compose-wait failed!\e[0m"
			exit -1	
		fi		
	else
		echo -e "\e[31mCannot Download docker-compose. Please manually download it.\e[0m" 
		exit -1
	fi
fi
echo -e "\e[32mMake wait executable!\e[0m"
chmod +x wait

echo -e "\e[32m Add to firefox about:config\e[0m"

echo -e "\e[33m" 
cat <<HERE
  "identity.fxaccounts.auth.uri": "https://api.$DOMAIN_NAME/v1",
  "identity.fxaccounts.remote.root": "https://www.$DOMAIN_NAME/",
  "identity.fxaccounts.remote.oauth.uri": "https://oauth.$DOMAIN_NAME/v1",
  "identity.fxaccounts.remote.profile.uri": "https://profile.$DOMAIN_NAME/v1",
  "identity.sync.tokenserver.uri": "https://token.$DOMAIN_NAME/token/1.0/sync/1.5",
HERE

echo -e "\e[0m" #reset

echo -e "\e[32m Config for Firefox android\e[0m"

echo -e "\e[33m" 
cat <<HERE
"identity.fxaccounts.auth.uri":"https://api.$DOMAIN_NAME/v1",
"identity.fxaccounts.remote.oauth.uri":"https://oauth.$DOMAIN_NAME/v1",
"identity.fxaccounts.remote.profile.uri":"https://profile.$DOMAIN_NAME/v1",
"identity.fxaccounts.remote.webchannel.uri":"https://www.$DOMAIN_NAME",

APPEND/PREPEND https://www.$DOMAIN_NAME to "webchannel.allowObject.urlWhitelist"

HERE

echo -e "\e[0m" #reset


echo -e "\e[32m Check sigincode \e[0m"

echo -e "\e[33m" 
cat  <<HERE
	docker-compose logs fxa-auth-local-mail-helper |grep -i code
HERE
echo -e "\e[0m" 

echo -e "\e[32m Or (Assume your account example@test.local) \e[0m"
echo -e "\e[33m" 
cat  <<HERE
	Get Code: curl http://127.0.0.1:9001/mail/example
	Clean up: curl -X DELETE http://127.0.0.1:9001/mail/example
HERE
echo -e "\e[0m" 


echo -e "\e[32m After renew certs: \e[0m"

echo -e "\e[33m" 
cat  <<HERE
	docker-compose exec nginx nginx -s reload
HERE
echo -e "\e[0m" 

