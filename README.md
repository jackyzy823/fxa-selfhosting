# Self hosted Firefox Accounts server

## Requirements
1. At least 2G RAM
2. Docker
3. Docker-compose(v1.29.0+) or docker image `docker-compose` or `docker compose` plugin (Note go version's docker-compose ignore driver:none see https://github.com/docker/compose/issues/8578)

## Installation
1. Create dns records for content-server(default:www)  profile-server(default:profile) syncserver(default:token)  auth-server(default:api) oauth-server(default:oauth) graphql-api(default:graphql) , Details in config.yml.sample domain section. They should share same base(APEX) domain name.
2. Make certs for content-server(default:www)  profile-server(default:profile) syncserver(default:token)  auth-server(default:api) oauth-server(default:oauth) graphql-api(default:graphql), or a wildcard cert for all subdomains (Recommended).
3. Copy config.yml.sample to config.yml and edit it with your real config.
4. Run ./init.sh after everytime you edit config.yml or anything in \_init to generate new docker-compose.yml and other configs in destination folder \`pwd\`/dest.
5. <optional> If you have demands on alternative networking mode, you can pick the most suitable networking and certificate mode from examples folder and set it up. For example if you want to use reverse proxy , please see examples/reverse\_proxy\_\*
6. cd to destination folder and docker compose up -d
7. Wait util all service working. 
8. Config your firefox accroding to instructions from ./init.sh 's output
9. If you upgrade fxa version do `docker-compose up -d` to replace changed containers.
10. Upgrade fxa version everytime when you upgrade this repo.

## Note
1. `init.sh` will create all files in `$DEST` (\`pwd\`/dest for default) folder for deployment. so make sure persistenpath should be relative to `$DEST` if using relative path
2. you can change dest folder via `DEST=somefolder ./init.sh`

## Notice for upgrading from v1.277.3

Now firefox use `oauth_webchannel_v1` instead of `fx_desktop_v3` as context param.
If you still want to use `fx_desktop_v3` , remeber to set `identity.fxaccounts.oauth.enabled` to false. However content-server may not work in this situation.
Note in future , firefox or fxa may remove `fx_desktop_v3` support.

## Notice for upgrading from v1.242.4
1. [BREAKING] mysql from 5.7 to 8.0 (It is recommended to use version after 8.0.16 since it have auto upgrade feature, otherwise you need to manually do `mysql_upgrade`)

## Notice for upgrading from v1.215.2
1. Please upgrade your `docker-compose` which support `service_completed_successfully` of depends\_on condition. see: `https://github.com/compose-spec/compose-spec`
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
4. [] limit docker-compose each container's resources
5. [x] firefox-send
6. [x] firefox fenix
7. [x] mozilla-services/channelserver
8. [ ] autotest with pyfxa or application-services/components/fxa-client

## Optional changes to firefox about:config for optimization
```
webextensions.storage.sync.enabled:true
services.sync.extension-storage.skipPercentageChance = 0  // to never skip sync for ext-storage ref:https://bugzilla.mozilla.org/show_bug.cgi?id=1621806
services.sync.scheduler.activeInterval = 10
services.sync.scheduler.fxa.singleDeviceInterval = 10
services.sync.scheduler.idleInterval = 10
services.sync.scheduler.idleTime = 10
services.sync.scheduler.immediateInterval = 10
services.sync.syncInterval = 60
services.sync.syncThreshold = 10
```

More about:config
https://github.com/mozilla/fxa/blob/main/packages/fxa-dev-launcher/profile.mjs

## For who want to use Fenix
1. (Done by default) you need edit `/_init/auth/oauthserver-prod.json` edit fenix' redirecturi and add scope 
```json
"scope": "https://identity.mozilla.com/tokens/session"
```
2. (Done by default) edit `_init/content/contentserver-prod.json`  `oldsync` redirecturi `oauth/success/a2270f727f45f648` 

### Client (Fenix)
Install newest version and open the app. Then go to
1. Settings
2. About Firefox
3. Click Firefox icon 5 times
4. Go back
5. Edit "Custom Firefox Account server" -> content server url (For example: https://www.fxa.example.local) and "Custom Sync server" -> sync server url (For example: https://token.fxa.example.local/token/1.0/sync/1.5")


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
```javascript
pairingChannelServerUri: "wss://channelserver.services.mozilla.com",
pairingClients: [ "3c49430b43dfba77", "a2270f727f45f648", "1b1a3e44c54fbb58" ],
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
