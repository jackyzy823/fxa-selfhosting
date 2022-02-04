set -x

DEST=${DEST:-dest}

echo "\e[32mOutput to $DEST\e[om"
mkdir -p $DEST
cp -r _init $DEST/

# define yq && ytt function
yq() {
  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq:4.13.2 "$@"
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
docker image inspect mikefarah/yq:4.13.2 >/dev/null 2>&1
should_del_yq=$?  #0 exists 1 not exists

if test "$should_del_yq" == "1"; then
  echo -e "\e[32mInstall mikefarah/yq:4.13.2. Will delete after used.\e[0m"
  docker pull mikefarah/yq:4.13.2  > /dev/null  2>&1
fi

docker image inspect k14s/image@sha256:1100ed870cd6bdbef229f650f044cb03e91566c7ee0c7bfdbc08efc6196a41d8 >/dev/null 2>&1
should_del_ytt=$?
if test "$should_del_ytt" == "1"; then
  echo -e "\e[32mInstall ytt from k14s/image. Will delete after used.\e[0m"
  docker pull k14s/image@sha256:1100ed870cd6bdbef229f650f044cb03e91566c7ee0c7bfdbc08efc6196a41d8  > /dev/null  2>&1
fi


## since all inter-container communications are using internal url. so no necessary start reverse proxy first.
# if test $(yq e .nginx.listener config.yml ) != "443" ; then
# 	echo -e "\e[31mYou still need a proxy to serve at 443 before docker-compose up\e[0m"
# 	echo -e "\e[31mSee examples/reverse_proxy \e[0m"
# fi

if test $(yq e .secrets.authsecret config.yml ) == "What3v3r" ; then
      yq eval -i ".secrets.authsecret =\"$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)\""  config.yml
fi

if test $(yq e .secrets.pushboxkey config.yml ) == "YOUR_LONG_ENOUGH_RANDOM_STRING" ; then
      yq eval -i ".secrets.pushboxkey =\"$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)\""  config.yml
fi

if test $(yq e .secrets.flowidkey config.yml ) == "MY_FLOW_ID_KEY" ; then
      yq eval -i ".secrets.flowidkey =\"$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)\""  config.yml
fi

if test $(yq e .secrets.profileserver_authsecret_bearertoken config.yml ) == "I_DONT_WANT_TO_CHANGE_YOU" ; then
      yq eval -i ".secrets.profileserver_authsecret_bearertoken =\"$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)\""  config.yml
fi

if test $(yq e .secrets.supportpanel_authsecret_bearertoken config.yml ) == "SUPPORT_PANEL_IS_NOT_SUPPORTED" ; then
      yq eval -i ".secrets.supportpanel_authsecret_bearertoken =\"$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)\""  config.yml
fi


cp config.yml $DEST/

# TODO check if these ytts success
echo -e "\e[32mgenerate _init/auth/oauthserver-prod.json\e[0m"
ytt -f $DEST/config.yml  -f $DEST/_init/auth/oauthserver-prod.tmpl.yml  -o json > $DEST/_init/auth/oauthserver-prod.json
if [ $? -ne 0 ]; then
	echo -e "\e[31mgenerate _init/auth/oauthserver-prod.json error \e[0m" 
	exit -1
fi
rm $DEST/_init/auth/oauthserver-prod.tmpl.yml

echo -e "\e[32mgenerate _init/content/contentserver-prod.json\e[0m"
ytt -f $DEST/config.yml  -f  $DEST/_init/content/contentserver-prod.tmpl.yml  -o json > $DEST/_init/content/contentserver-prod.json
if [ $? -ne 0 ]; then
	echo -e "\e[31mgenerate _init/content/contentserver-prod.json error\e[0m" 
	exit -1
fi
rm $DEST/_init/content/contentserver-prod.tmpl.yml

echo -e "\e[32mgenerate docker-compose.yml\e[0m"
ytt -f $DEST/config.yml  -f  docker-compose.tmpl.yml > $DEST/docker-compose.yml
if [ $? -ne 0 ]; then
	echo -e "\e[31mgenerate docker-compose.yml error \e[0m" 
	exit -1
fi



# echo -e "\e[32mPlease make sure that you configured subdomains and their certs: www.$DOMAIN_NAME profile.$DOMAIN_NAME token.$DOMAIN_NAME  api.$DOMAIN_NAME oauth.$DOMAIN_NAME (api.$DOMAIN_NAME and oauth.$DOMAIN_NAME must use same cert) \e[0m"
# do this to ensure .env 's   PERSISTENCEPATH  relate to docker-compose.yml
# echo -e "\e[32mPlease make sure that 0.0.0.0:443 and 127.0.0.1:9001 is not used\e[0m"




# [TODO] make download wait in containers too and depends_on service_completed_successfully
#download wait
if [ ! -f wait ] ;then
	echo -e "\e[32mDownloading docker-compose-wait from https://github.com/ufoscout/docker-compose-wait\e[0m"
	if [ -x "$(command -v wget)" ]; then
		if wget -O $DEST/wait --quiet https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait ;then
			echo -e "\e[32mDownload docker-compose-wait successfully!\e[0m"
		else
			echo -e "\e[31mDownload docker-compose-wait failed!\e[0m"
			exit -1
		fi
	elif [ -x "$(command -v curl)" ]; then
		if curl --silent -L -o $DEST/wait https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait ;then
			echo -e "\e[32mDownload docker-compose-wait successfully!\e[0m"
		else
			echo -e "\e[31mDownload docker-compose-wait failed!\e[0m"
			exit -1	
		fi		
	else
		echo -e "\e[31mCannot Download docker-compose-wait. Please manually download it.\e[0m" 
		exit -1
	fi
fi
echo -e "\e[32mMake wait executable!\e[0m"
chmod +x $DEST/wait


set +x 

echo -e "\e[32mAdd to firefox about:config\e[0m"

DOMAIN_NAME=$(yq e .domain.name config.yml)
CONTENT_SUB=$(yq e .domain.content config.yml)
AUTH_SUB=$(yq e .domain.auth config.yml)
OAUTH_SUB=$(yq e .domain.oauth config.yml)
PROFILE_SUB=$(yq e .domain.profile config.yml)
SYNC_SUB=$(yq e .domain.sync config.yml)




echo -e "\e[33m" 
cat <<HERE
  "identity.fxaccounts.auth.uri": "https://$AUTH_SUB.$DOMAIN_NAME/v1",
  "identity.fxaccounts.remote.root": "https://$CONTENT_SUB.$DOMAIN_NAME/",
  "identity.fxaccounts.remote.oauth.uri": "https://$OAUTH_SUB.$DOMAIN_NAME/v1",
  "identity.fxaccounts.remote.profile.uri": "https://$PROFILE_SUB.$DOMAIN_NAME/v1",
  "identity.sync.tokenserver.uri": "https://$SYNC_SUB.$DOMAIN_NAME/token/1.0/sync/1.5",
HERE

if test $(yq e .option.channelserver.enable config.yml ) == "true" ; then
	CHANNELSERVER_SUB=$(yq e .domain.channelserver config.yml)
	cat <<HERE
"identity.fxaccounts.remote.pairing.uri": "wss://$CHANNELSERVER_SUB.$DOMAIN_NAME",
HERE
fi

# TODO: yq r only once
if test $(yq e .option.webext_storagesync.enable config.yml ) == "true" ; then
	KINTO_SUB=$(yq e .domain.kinto config.yml)
	cat <<HERE
  "webextensions.storage.sync.kinto": true
  "webextensions.storage.sync.serverURL": "https://$KINTO_SUB.$DOMAIN_NAME/v1"
HERE
fi

if test $(yq e .option.send.enable config.yml ) == "true" ; then
	SNED_SUB=$(yq e .domain.send config.yml)
	cat <<HERE
  "identity.fxaccounts.service.sendLoginUrl": "https://$SNED_SUB.$DOMAIN_NAME/login/"
HERE
fi

echo -e "\e[0m" #reset

echo -e "\e[32m Config for Fenix(Firefox android)\e[0m"

echo -e "\e[33m" 
cat <<HERE
  Enable "Secret Menu"  See: https://github.com/mozilla-mobile/fenix/pull/8916
  "Custom Firefox Account server":"https://$AUTH_SUB.$DOMAIN_NAME/v1",
  "Custom Sync server": "https://$SYNC_SUB.$DOMAIN_NAME/token/1.0/sync/1.5",
HERE

echo -e "\e[0m" #reset

if test "$(yq e .mail.type config.yml)" == "localhelper" ; then
	echo -e "\e[32m Check sigincode \e[0m"
	echo -e "\e[33m" 
	cat  <<HERE
		docker-compose logs fxa-auth-local-mail-helper |grep -i code
HERE

	echo -e "\e[0m" 

	# TODO replace 127.0.0.1:9001 to yq r
	echo -e "\e[32m Or (Assume your account example@test.local) \e[0m"
	echo -e "\e[33m" 
	localhelperweb=$(yq e .mail.localhelper.web config.yml)
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

set -x

# cleanup 
if test "$should_del_yq" == "1"; then
	echo -e "\e[32mRemove mikefarah/yq\e[0m"
	docker image rm mikefarah/yq:4.13.2 >/dev/null 2>&1
fi
if test "$should_del_ytt" == "1"; then
	echo -e "\e[32mRemove ytt\e[0m"
	docker image rm k14s/image@sha256:1100ed870cd6bdbef229f650f044cb03e91566c7ee0c7bfdbc08efc6196a41d8 >/dev/null 2>&1
fi
