# use under your own risk!!!
# ref: https://gist.github.com/fntlnz/cf14feb5a46b2eda428e000157447309
openssl genrsa -out rootCA.key 4096
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 7300 -subj "/C=MZ/O=FxA SefHosting Project/CN=FxA SelfHosting Root CA"  -out rootCA.crt

openssl genrsa 2048 > wild.fxa.example.local.key

# for RHEL replace /etc/ssl/openssl.cnf with  /etc/pki/tls/openssl.cnf

CNF_PATH=`openssl version -d |  sed -r "s/.*\"(.*?)\".*/\1/" `
openssl req -new -sha256 \
    -key wild.fxa.example.local.key \
    -subj "/C=MZ/O=FxA Hosting/CN=*.fxa.example.local" \
    -reqexts SAN \
    -config <(cat $CNF_PATH/openssl.cnf \
        <(printf "\n[SAN]\nsubjectAltName=DNS:*.fxa.example.local")) \
    -out wild.fxa.example.local.csr

openssl x509 -req -extfile <(printf "subjectAltName=DNS:*.fxa.example.local") -in wild.fxa.example.local.csr -sha256 -days 3650 -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out wild.fxa.example.local.cer 
