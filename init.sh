# define yq && ytt function
yq() {
  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq yq "$@"
}

ytt() {
	docker run --rm -i -v "${PWD}":/workdir -w /workdir k14s/image@sha256:1100ed870cd6bdbef229f650f044cb03e91566c7ee0c7bfdbc08efc6196a41d8 ytt "$@"
}

# check config exists
if [ ! -f config.yml ] ; then
	echo -e "\e[31mCannot Found config.yml\e[0m"
	exit -1
fi

# if mikefarah/yq exists we do not delete after used.
docker image inspect mikefarah/yq >/dev/null 2>&1 
should_del_yq=$?  #0 exists 1 not exists

if test "$should_del_yq" == "1"; then
	echo -e "\e[32mInstall mikefarah/yq. Will delete after used.\e[0m"
	docker pull mikefarah/yq  > /dev/null  2>&1 
fi

docker image inspect k14s/image@sha256:1100ed870cd6bdbef229f650f044cb03e91566c7ee0c7bfdbc08efc6196a41d8 >/dev/null 2>&1 
should_del_ytt=$?
if test "$should_del_ytt" == "1"; then
	echo -e "\e[32mInstall ytt from k14s/image. Will delete after used.\e[0m"
	docker pull k14s/image@sha256:1100ed870cd6bdbef229f650f044cb03e91566c7ee0c7bfdbc08efc6196a41d8  > /dev/null  2>&1 
fi




persistencepath=$(realpath $(yq r config.yml persistencepath))

if [ ! -d  $persistencepath/public ] ; then
	echo -e "\e[32mmake folder $persistencepath/public and set it all writalbe for profile avatar\e[0m"
	mkdir $persistencepath/public && chmod 777 $persistencepath/public
fi

if test $(stat -c %a $persistencepath/public) != "777" ; then 
	chmod 777 $persistencepath/public
fi
if test $(yq r config.yml option.notes.enable) == "true" ||  test $(yq r config.yml option.webext_storagesync.enable) == "true" ; then
	if [ ! -d  $persistencepath/postgres_data ] ; then
		echo -e "\e[32mmake folder $persistencepath/postgres_data for postgres used in firefox notes or webextension storage.sync\e[0m"
		mkdir $persistencepath/postgres_data
	fi
fi

if [ ! -d  $persistencepath/mysql_data ] ; then
	echo -e "\e[32mmake folder $persistencepath/mysql_data for mysql used in all fxa stack\e[0m"
	mkdir $persistencepath/mysql_data
fi

if test $(yq r config.yml nginx.listener) != "443" ; then 
	echo -e "\e[31mYou still need a proxy to serve at 443 before docker-compose up\e[0m"
	echo -e "\e[31mSee examples/reverse_proxy \e[0m"
fi

# TODO check if these ytts success
echo -e "\e[32mgenerate _init/auth/oauthserver-prod.json\e[0m"
ytt -f config.yml  -f  _init/auth/oauthserver-prod.tmpl.yml  -o json > _init/auth/oauthserver-prod.json
if [ $? -ne 0 ]; then 
	echo -e "\e[31mgenerate _init/auth/oauthserver-prod.json error \e[0m" 
	exit -1
fi
echo -e "\e[32mgenerate _init/content/contentserver-prod.json\e[0m"
ytt -f config.yml  -f  _init/content/contentserver-prod.tmpl.yml  -o json > _init/content/contentserver-prod.json
if [ $? -ne 0 ]; then 
	echo -e "\e[31mgenerate _init/content/contentserver-prod.json error\e[0m" 
	exit -1
fi
echo -e "\e[32mgenerate docker-compose.yml\e[0m"
ytt -f config.yml  -f  docker-compose.tmpl.yml > docker-compose.yml
if [ $? -ne 0 ]; then 
	echo -e "\e[31mgenerate docker-compose.yml error \e[0m" 
	exit -1
fi
### use yq to write new secrets! No you can't  https://github.com/mikefarah/yq/issues/351
## may be we can sed -i "s/#@data\/values/#@data\/values\n---/g" config.yml
# if test $(yq r config.yml secrets.pushboxkey) == "YOUR_LONG_ENOUGH_RANDOM_STRING" ; then 
# 	yq w  -d1 -i config.yml secrets.pushboxkey `head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20`
# fi



# echo -e "\e[32mPlease make sure that you configured subdomains and their certs: www.$DOMAIN_NAME profile.$DOMAIN_NAME token.$DOMAIN_NAME  api.$DOMAIN_NAME oauth.$DOMAIN_NAME (api.$DOMAIN_NAME and oauth.$DOMAIN_NAME must use same cert) \e[0m"
# do this to ensure .env 's   PERSISTENCEPATH  relate to docker-compose.yml
# echo -e "\e[32mPlease make sure that 0.0.0.0:443 and 127.0.0.1:9001 is not used\e[0m"





#download wait
if [ ! -f wait ] ;then 
	echo -e "\e[32mDownloading docker-compose-wait from https://github.com/ufoscout/docker-compose-wait\e[0m"
	if [ -x "$(command -v wget)" ]; then
		if wget -O wait --quiet https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait ;then
			echo -e "\e[32mDownload docker-compose-wait successfully!\e[0m"
		else
			echo -e "\e[31mDownload docker-compose-wait failed!\e[0m"
			exit -1
		fi
	elif [ -x "$(command -v curl)" ]; then
		if curl --silent -o wait https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait ;then
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

echo -e "\e[32mAdd to firefox about:config\e[0m"

DOMAIN_NAME=$(yq r config.yml domain.name)
CONTENT_SUB=$(yq r config.yml domain.content)
AUTH_SUB=$(yq r config.yml domain.auth)
OAUTH_SUB=$(yq r config.yml domain.oauth)
PROFILE_SUB=$(yq r config.yml domain.profile)
SYNC_SUB=$(yq r config.yml domain.sync)
KINTO_SUB=$(yq r config.yml domain.kinto)
SNED_SUB=$(yq r config.yml domain.send)

echo -e "\e[33m" 
cat <<HERE
  "identity.fxaccounts.auth.uri": "https://$AUTH_SUB.$DOMAIN_NAME/v1",
  "identity.fxaccounts.remote.root": "https://$CONTENT_SUB.$DOMAIN_NAME/",
  "identity.fxaccounts.remote.oauth.uri": "https://$OAUTH_SUB.$DOMAIN_NAME/v1",
  "identity.fxaccounts.remote.profile.uri": "https://$PROFILE_SUB.$DOMAIN_NAME/v1",
  "identity.sync.tokenserver.uri": "https://$SYNC_SUB.$DOMAIN_NAME/token/1.0/sync/1.5",
HERE

# TODO: yq r only once
if test $(yq r config.yml option.webext_storagesync.enable) == "true" ; then
	cat <<HERE
  "webextensions.storage.sync.kinto": true
  "webextensions.storage.sync.serverURL": "https://$KINTO_SUB.$DOMAIN_NAME/v1"
HERE
fi

if test $(yq r config.yml option.send.enable) == "true" ; then
	cat <<HERE
  "identity.fxaccounts.service.sendLoginUrl": "https://$SNED_SUB.$DOMAIN_NAME/login/"
HERE
fi

echo -e "\e[0m" #reset

echo -e "\e[32m Config for Firefox android\e[0m"

echo -e "\e[33m" 
cat <<HERE
  "identity.fxaccounts.auth.uri":"https://$AUTH_SUB.$DOMAIN_NAME/v1",
  "identity.fxaccounts.remote.oauth.uri":"https://$OAUTH_SUB.$DOMAIN_NAME/v1",
  "identity.fxaccounts.remote.profile.uri":"https://$PROFILE_SUB.$DOMAIN_NAME/v1",
  "identity.fxaccounts.remote.webchannel.uri":"https://$CONTENT_SUB.$DOMAIN_NAME/",
  "identity.sync.tokenserver.uri": "https://$SYNC_SUB.$DOMAIN_NAME/token/1.0/sync/1.5",

  APPEND/PREPEND https://$CONTENT_SUB.$DOMAIN_NAME to "webchannel.allowObject.urlWhitelist"

HERE

echo -e "\e[0m" #reset

if test "$(yq r config.yml mail.type)" == "localhelper" ; then
	echo -e "\e[32m Check sigincode \e[0m"
	echo -e "\e[33m" 
	cat  <<HERE
		docker-compose logs fxa-auth-local-mail-helper |grep -i code
HERE

	echo -e "\e[0m" 

	# TODO replace 127.0.0.1:9001 to yq r
	echo -e "\e[32m Or (Assume your account example@test.local) \e[0m"
	echo -e "\e[33m" 
	localhelperweb=$(yq r config.yml mail.localhelper.web)
	cat  <<HERE
		Get Code: curl http://$localhelperweb/mail/example
		Clean up: curl -X DELETE http://$localhelperweb/mail/example
HERE
	echo -e "\e[0m" 

fi



echo -e "\e[32m After renew certs (not using reverse proxy): \e[0m"

echo -e "\e[33m" 
cat  <<HERE
	docker-compose exec nginx nginx -s reload
HERE
echo -e "\e[0m" 


# cleanup 
if test "$should_del_yq" == "1"; then
	echo -e "\e[32mRemove mikefarah/yq\e[0m"
	docker image rm mikefarah/yq >/dev/null 2>&1 
fi
if test "$should_del_ytt" == "1"; then
	echo -e "\e[32mRemove ytt\e[0m"
	docker image rm k14s/image@sha256:1100ed870cd6bdbef229f650f044cb03e91566c7ee0c7bfdbc08efc6196a41d8 >/dev/null 2>&1 
fi
