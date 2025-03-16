* How to setup test client.

1. Use `https://github.com/mozilla/fxa/tree/main/packages/fxa-dev-launcher` as launcher
  - To not install all fxa dependencies, just copy only this folder.
  - Add your own profiles in profile.mjs.
  - FXA_ENV: choose profile.
  - Note that the self hosted one's `token` server has prefix '/token/' in the path. It could easily be forgotten when copy-pasting from other profiles.
  - FXA_DESKTOP_CONTEXT: new oauth_webchannel_v1 old fx_desktop_v3. and oauth_webchannel_v1 will also set 'identity.fxaccounts.oauth.enabled': true automatically.
  - FIREFOX_BIN: set alternative Firefox path.
  - `npm run start`
2. Use `inotifywait` from `inotify-tools` and `certutil` from `nss-tools` to update the ROOT CA certificate of self sign certificate automatically.
  - Goto the path of temp profile of firefox-launch (~/tmp)
  - `inotifywait -m -e create . |  while read a b file; do echo "output"  $a  $b $file ; sleep 2 && certutil -A  -d  $file  -n fxaroot -t "C,," -i <Path_to_rootCA.crt> ; done`
  - Use `sleep` to wait firefox-launcher to finish creating profile.
  - Reference: https://stackoverflow.com/questions/32818361/how-to-install-one-certificate-automated-into-firefox-store https://github.com/FiloSottile/mkcert/blob/master/truststore_nss.go
3. Setup sync configuration.
  - TODO: set up sync percentage

