#import re
import json
from urllib.request import urlopen
#from urllib.parse import unquote_plus

v = json.loads(urlopen("https://api.accounts.firefox.com/").read())
print(v)
print(v.get("version"))

#page = urlopen("https://accounts.firefox.com").read()
#cfg = re.findall(r'''name=fxa-content-server/config content=(.*?)>''',page.decode())[0]
#print(json.loads(unquote_plus(cfg)).get("release"))
