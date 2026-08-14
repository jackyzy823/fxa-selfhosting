#import re
import json
from urllib.request import urlopen
#from urllib.parse import unquote_plus


# note: production use private repo now!
# {
#   "version": "1.342.4",
#   "commit": "a471db842534e768899bd7dc469d7fc711a2861f",
#   "source": "https://github.com/mozilla/fxa-private"
# }

v = json.loads(urlopen("https://api.accounts.firefox.com/").read())
print(v)
print(v.get("version"))

#page = urlopen("https://accounts.firefox.com").read()
#cfg = re.findall(r'''name=fxa-content-server/config content=(.*?)>''',page.decode())[0]
#print(json.loads(unquote_plus(cfg)).get("release"))
