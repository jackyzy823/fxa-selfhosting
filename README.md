# Self hosted Firefox Accounts server

## Requirements and Steps
1. at least 2G RAM
2. docker
3. docker-compose(v1.29.0+) or docker image `docker-compose` or `docker compose` plugin (Note go version's docker-compose ignore driver:none see https://github.com/docker/compose/issues/8578)
4. create dns records for content-server(default:www)  profile-server(default:profile) syncserver(default:token)  auth-server(default:api) oauth-server(default:oauth) graphql-api(default:graphql) , Details in config.yml.sample domain section. They should share same base(APEX) domain name.
5. make certs for content-server(default:www)  profile-server(default:profile) syncserver(default:token)  auth-server(default:api) oauth-server(default:oauth) graphql-api(default:graphql), or a wildcard cert for all subdomains (Recommended).
6. cp config.yml.sample to config.yml and edit it with your real config.
7. run ./init.sh after everytime you edit config.yml or anything in _init to generate new docker-compose.yml and other configs in destination folder `pwd`/dest`.
8. <optional> If you have demands on alternative networking mode, you can pick the most suitable networking and certificate mode from examples folder and set it up. For example if you want to use reverse proxy , please see examples/reverse_proxy_*
9. cd destination folder and docker compose up -d 
10. wait util all service working. 
11. config your firefox accroding to instructions from ./init.sh 's output 
12. If you upgrade fxa version do `docker-compose up -d` to replace changed containers.

## Note
1. `init.sh` will create all files in `$DEST` (`pwd`/dest for default) folder for deployment. so make sure persistenpath should be relative to `$DEST` if using relative path
2. you can change dest folder via `DEST=somefolder ./init.sh`

## Notice for upgrading from v1.215.2
1. Please upgrade your `docker-compose` which support `service_completed_successfully` of depends_on condition. see: `https://github.com/compose-spec/compose-spec`
2. [BREAKING] mysql from 5.6 to 5.7 so you need manual do `mysql_upgrade` , like `docker-compose exec mysqldb mysql_upgrade` .see mysql documention.

## Common Notice
if your about:config `useOAuthForSyncToken` is `true`. Please update syncserver docker image to latest.

## Some details
To avoid set permission of `public` folder (for storing profile image) in profile server. A one-shot root container is spawned to change `public` folder permission then exit.
So docker `rootless` mode is not supported.
<del>if one day aws-sdk-js support endpoint url env / fxa-profile support new S3(cfg.endpoint) . just use minio/minio to replace local.</del>

TODO:
1. [x] nginx + http2
2. [x] firefox notes with self kinto server
3. [x] use yq to generate secrests <del>use docker-compose->secrets to protoect secrets?</del>
4. lxmit docker-compose each container's resources
5. [x] firefox-send
6. [x] firefox fenix
7. [x] mozilla-services/channelserver
8. [ ] autotest with pyfxa or application-services/components/fxa-client

Related firefox about:config
webextensions.storage.sync.enabled:true
services.sync.extension-storage.skipPercentageChance 0  // to never skip sync for ext-storage ref:https://bugzilla.mozilla.org/show_bug.cgi?id=1621806

services.sync.scheduler.activeInterval :10
services.sync.scheduler.fxa.singleDeviceInterval :10  
services.sync.scheduler.idleInterval :10
services.sync.scheduler.idleTime :10
services.sync.scheduler.immediateInterval:10
services.sync.syncInterval: 60
services.sync.syncThreshold:10

More about:config
https://github.com/mozilla/fxa/blob/main/packages/fxa-dev-launcher/profile.js

## For who want to use fenix
1. you need edit `/_init/auth/oauthserver-prod.json` edit fenix' redirecturi and add scope `"scope": "https://identity.mozilla.com/tokens/session"`
2. edit `_init/content/contentserver-prod.json`  `oldsync` redirecturi `oauth/success/a2270f727f45f648` 
3. Client. 
<del>
1) git clone `fenix` and  `android-components`  under same folder
2) add local.properties in fenix , content : "autoPublish.android-components.dir=../android-components"
3) in `android-components` edit `components/feature/accounts/src/main/assets/extensions/fxawebchannel/manifest.json` add your content-server in `matches`  see issue https://github.com/mozilla-mobile/android-components/issues/6225 and etc
4) compile. i use `bitriseio/android-ndk` to build , you need no less than 10g memory (under my case). `docker run --rm -v <folder contain fenix and android-components>:/bitriseio/src -w /bitriseio/src/fenix bitriseio/android-ndk ./gradlew clean app:assembleGeckoBetaDebug
5) get apk from fenix/apk/build/outputs/......
</del>
6) install newest version and open app . Goto settings  -> about firefox -> click firefox icon 5 times -> go back -> edit your fxa server url and sync server url


## Notes (self build)
### webextension modification
```diff
diff --git a/src/background.js b/src/background.js
index 85da9e2..0aa878e 100644
--- a/src/background.js
+++ b/src/background.js
@@ -1,8 +1,12 @@
-const KINTO_SERVER = 'https://testpilot.settings.services.mozilla.com/v1';
+var KINTO_SERVER = 'https://kinto.<your_server>/v1/';
+
+// const KINTO_SERVER = 'https://testpilot.settings.services.mozilla.com/v1';
 // XXX: Read this from Kinto fxa-params
-const FXA_CLIENT_ID = 'a3dbd8c5a6fd93e2';
-const FXA_OAUTH_SERVER = 'https://oauth.accounts.firefox.com/v1';
-const FXA_PROFILE_SERVER = 'https://profile.accounts.firefox.com/v1';
+var FXA_CLIENT_ID = 'a3dbd8c5a6fd93e2'; 
+var FXA_OAUTH_SERVER = 'https://oauth.<your_server>/v1';
+var FXA_CONTENT_SERVER = 'https://www.<your_server>';
+var FXA_PROFILE_SERVER = 'https://profile.<your_server>/v1';
+
 const FXA_SCOPES = ['profile', 'https://identity.mozilla.com/apps/notes'];
 let isEditorReady = false;
 let editorConnectedDeferred;
@@ -26,7 +30,10 @@ function fetchProfile(credentials) {
 }
 
 function authenticate() {
-  const fxaKeysUtil = new fxaCryptoRelier.OAuthUtils();
+  const fxaKeysUtil = new fxaCryptoRelier.OAuthUtils({
+    oauthServer:FXA_OAUTH_SERVER,
+    contentServer:FXA_CONTENT_SERVER
+  });
     chrome.runtime.sendMessage({
       action: 'sync-opening'
     });
```

### Android modification
`native/app/utils/constants.js`
```javascript
export const KINTO_SERVER_URL = 'https://testpilot.settings.services.mozilla.com/v1';
export const FXA_PROFILE_SERVER = 'https://profile.accounts.firefox.com/v1';
export const FXA_CONTENT_SERVER = 'https://accounts.firefox.com';
export const FXA_OAUTH_SERVER = 'https://oauth.accounts.firefox.com/v1';
export const FXA_OAUTH_CLIENT_ID = '7f368c6886429f19';
```

`native/android/app/src/main/java/com/notes/fxaclient/FxaClientModule.java`
```java
private static final String CLIENT_ID = "7f368c6886429f19";
private static final String CONFIG_URL = "https://accounts.firefox.com";
```

## About Channelserver / pairing

pairingChannelServerUri: "wss://channelserver.services.mozilla.com"
pairingClients: [ "3c49430b43dfba77", "a2270f727f45f648", "1b1a3e44c54fbb58" ]

```javascript
  pairing: {
    clients: {
      default: [
        '3c49430b43dfba77', // Reference browser
        'a2270f727f45f648', // Fenix
        '1b1a3e44c54fbb58', // Firefox for iOS
      ],
      doc:
        'OAuth Client IDs that are allowed to pair. Remove all clients from this list to disable pairing.',
      env: 'PAIRING_CLIENTS',
      format: Array,
    },
    server_base_uri: {
      default: 'wss://channelserver.services.mozilla.com`1',
      doc: 'The url of the Pairing channel server.',
      env: 'PAIRING_SERVER_BASE_URI',
    },
  },
```
