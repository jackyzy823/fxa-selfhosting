#!/usr/bin/env python3
# Dump sync data from db directly with fxa key info
# pip install --upgrade pip
# pip install mysql-connector-python pyfxa pycryptodome
import mysql.connector

from fxa.crypto import quick_stretch_password , xor ,derive_key
from fxa._utils import hexstr
import json
import hmac
import hashlib
import base64

from Crypto.Cipher import AES
from Crypto.Protocol.KDF import scrypt,HKDF
import pprint


def decrypt_payload(record, key_bundle):
    j = json.loads(record)
    # Always check the hmac before decrypting anything.
    expected_hmac = hmac.new(key_bundle.hmac_key, j['ciphertext'].encode(), hashlib.sha256).hexdigest()
    if j['hmac'] != expected_hmac:
        raise ValueError("HMAC mismatch: %s != %s" % (j['hmac'], expected_hmac))
    ciphertext = base64.b64decode(j['ciphertext'])
    iv = base64.b64decode(j['IV'])
    aes = AES.new(key_bundle.encryption_key, AES.MODE_CBC, iv)
    plaintext = aes.decrypt(ciphertext).strip()
    # Remove any CBC block padding, assuming it's a well-formed JSON payload.
    plaintext = plaintext[:plaintext.rfind(b"}") + 1]
    return json.loads(plaintext)


class KeyBundle:
    def __init__(self, encryption_key, hmac_key):
        self.encryption_key = encryption_key
        self.hmac_key = hmac_key

    @classmethod
    def fromMasterKey(cls, master_key, info):
        key_material = derive_key(master_key , info,size=64)
        #HKDF(master_key , key_len = 64, salt = None, hashmod = SHA256 ,context=info.encode())
        return cls(key_material[:32], key_material[32:])

# change host/port/user/password
# also change database name if not default
ctx = mysql.connector.connect(host="127.0.0.1" , user="root")

cur = ctx.cursor()


cur.execute("select users.uid  , accounts.email, accounts.kA , accounts.wrapWrapKb, accounts.authSalt, accounts.verifyHash ,accounts.verifierVersion   from sync.users as users left join fxa.accounts as accounts on unhex(substr(users.email,1,32)) = accounts.uid ")
res = cur.fetchall()

## Ref: https://mozilla.github.io/ecosystem-platform/fxa-engineering/fxa-onepw-protocol
## Ref: https://github.com/mozilla/fxa/blob/main/packages/fxa-auth-server/lib/crypto/password.js
## https://github.com/tlambertz/sync-decrypter
## https://gist.github.com/Killeroid/17c0695017950ca008917fda23270af2

for info in res:
    sync_user_id = info[0]
    email = info[1]
    kA = info[2]
    wrapWrapKb = info[3]
    authSalt = info[4]
    verifierVersion = info[6]
    
    stretchpwd = quick_stretch_password(email, "!@#$QWER")
    authPW = derive_key(stretchpwd,"authPW")


    ### wtf bigStretchedPW  is hex format and no document for onepw protocol says that??
    # https://github.com/mozilla/fxa/blob/main/packages/fxa-auth-server/lib/crypto/scrypt.js#L60
    bigStretchedPW = hexstr(scrypt(authPW , salt = authSalt , N=64 * 1024 , r=8, p=1 , key_len =32)).encode()

    wrapwrapKey = derive_key(bigStretchedPW, "wrapwrapKey")
    wrapKb = xor(wrapwrapKey , wrapWrapKb)

    unwrapBkey = derive_key(stretchpwd, "unwrapBkey")
    kB = xor(wrapKb ,  unwrapBkey )

    #sync_keys = KeyBundle.fromMasterKey(kB , "identity.mozilla.com/picl/v1/oldsync")
    # we use fxa' derive_key here so no need namespace "identity.mozilla.com/picl/v1/"
    sync_keys = KeyBundle.fromMasterKey(kB , "oldsync")

    cur.execute("""select payload from  sync.bso where userid = %s and collection = (select collectionid from sync.collections where name="crypto") and id='keys'""" , (sync_user_id , ))
    keyinfo = cur.fetchone()
    keys = decrypt_payload(keyinfo[0], sync_keys)
    bulk_keys = KeyBundle(base64.b64decode(keys["default"][0]), base64.b64decode(keys["default"][1]))

    cur.execute("""select payload , modified , ttl ,sync.collections.name from sync.bso left join sync.collections on sync.bso.collection = sync.collections.collectionid  where userid = %s and collection not in ( select collectionid from sync.collections where name in ("crypto" ,"prefs" ,"meta") )""" , (sync_user_id, ))

    records = cur.fetchall()
    print("For user:", email)
    for i in records:
        print("Type",i[3])
        pprint.pprint(decrypt_payload(i[0] , bulk_keys))

