import json
import sys
import os.path

# Can be overridden prior to calling get_emote_list
EMOTE_PATH = os.path.normpath(__file__ + "/../emotes")

# Only a handful of emotes actually make use of the fact that the check is a
# regex. We don't use regexes, so instead, we translate those few emotes into
# a few actual strings that would match. Several have the "-?" optional hyphen
# or a bit of alternation, and all of them have at least one escaped special.
TRANSLATIONS = """
\\:-?\\) :) :-)
\\:-?\\( :( :-(
\\:-?D :D :-D
\\&gt\\;\\( >(
\\:-?[z|Z|\\|] :-z :-Z :-| :z :Z :|
[oO](_|\\.)[oO] o_o O_O o.o O.O
B-?\\) B-) B)
\\:-?(o|O) :-o :-O :o :O
\\&lt\\;3 <3
\\:-?[\\\\/] :-\\ :-/ :\\ :/
\\;-?\\) ;) ;-)
\\:-?(p|P) :-p :-P :p :P
\\;-?(p|P) ;-p ;-P ;p ;P
R-?\\) R) R-)
"""
emote_list = None
old_emotes = { # Add older Twitch emotes here:
	"devicatEH": 1291575, "devicatGRR": 1291582,
	"devicatSPOOK": 1291574, "devicatNOM": 819947,
	"devicatCCB": 1857241, "devicatTYVM": 1857245,
	"devicatCHII": 1857246, "devicatSMUG": 1857248,
	"devicatCAKE": 1857251, "devicatGIFT": 1112114,
	"devicatHYPU": 302139016, "devicatHypu": 302139016,
	# Or renames:
	"devicatBOX": "devicatGift", "devicatCUP": "devicatTea",
	"devicatSPARKLE": "devicatShiny", "devicatGLO": "devicatGlo1",
}
old_ffz = { # Add older FFZ emotes here:
	"DeviCry": 70993, "DeviSquee": 70996, "DeviFear": 70998, "DeviRawr": 70999,
}

# 20200514: Devi renamed a bunch of her emotes, lowercasing their emote IDs.
for tail in "Love Shy Grr UwU Eh Cozy Lurk Hiyo Cool Nom LoL Hug Aww Cry Spook Butt Glo2 Pow Magic Flag Tada Lvlup".split():
	old_emotes["devicat" + tail.upper()] = "devicat" + tail

def get_emote_list():
	global emote_list
	if emote_list: return emote_list
	try:
		with open(EMOTE_PATH + "/emote_list.json") as f:
			data = json.load(f)
	except FileNotFoundError:
		print("Downloading emote list...", file=sys.stderr)
		import requests
		# TODO: Have other ways of getting hold of a client ID than having
		# Mustard Mine installed
		# TODO: Retrieve historical emotes as well. Use the newest for any
		# given keyword, but support the older ones eg noobsKnife, devicatEH
		sys.path.append("../mustard-mine")
		import config
		req = requests.get("https://api.twitch.tv/kraken/chat/emoticons", headers={
			"Client-ID": config.CLIENT_ID,
			"Accept": "application/vnd.twitchtv.v5+json",
			"Accept-Encoding": None, # The Twitch servers don't like how python-requests is okay with compressed responses (???)
		})
		req.raise_for_status()
		data = req.json()
		with open(EMOTE_PATH + "/emote_list.json", "w") as f:
			json.dump(data, f)
	emote_list = {em["regex"]: "https://static-cdn.jtvnw.net/emoticons/v1/%s/1.0" % em["id"]
		for em in reversed(data["emoticons"])}
	for name, id in old_emotes.items():
		if name not in emote_list:
			if isinstance(id, str):
				# Alias an old name to a new name (will bomb if the replacement doesn't exist)
				emote_list[name] = emote_list[id]
			else:
				# Provide the emote ID for a legacy emote
				emote_list[name] = "https://static-cdn.jtvnw.net/emoticons/v1/%s/1.0" % id
	for trn in TRANSLATIONS.split("\n"):
		pat, *em = trn.split(" ")
		for e in em: emote_list[e] = emote_list[pat]
	return emote_list

def _load_emotes(desc, fn, url, xfrm):
	"""Helper for load_bttv() and load_ffz()"""
	emote_list = get_emote_list()
	try:
		with open(EMOTE_PATH + fn) as f:
			data = json.load(f)
	except FileNotFoundError:
		print("Downloading %s emote list..." % desc, file=sys.stderr)
		import requests
		req = requests.get(url)
		req.raise_for_status()
		data = xfrm(req.json())
		with open(EMOTE_PATH + fn, "w") as f:
			json.dump(data, f)
	emote_list.update(data)

def _xfrm_bttv(data):
	"""Helper for load_bttv - parse a BTTV-format JSON file"""
	template = data["urlTemplate"].replace("{{image}}", "1x")
	if template.startswith("//"): template = "https:" + template
	return {em["code"]: template.replace("{{id}}", em["id"])
		for em in data["emotes"]}

def load_bttv(*channels):
	"""Load BTTV emotes for zero or more channels

	If no channels are specified, loads only the global emotes. Otherwise,
	emotes for the named channels (by username) will also be loaded.

	Mutates the emote list used by convert_emotes().

	NOTE: The channel names are not sanitized and should come from source code.
	"""
	_load_emotes("BTTV global", "/bttv.json", "https://api.betterttv.net/2/emotes", _xfrm_bttv)
	for channel in channels:
		_load_emotes(channel + " BTTV", "/bttv_%s.json" % channel,
			"https://api.betterttv.net/2/channels/" + channel, _xfrm_bttv)

def _xfrm_ffz(data):
	"""Helper for load_ffz - parse a FFZ-format JSON file"""
	return {em["code"]: em["images"]["1x"] for em in data}

def load_ffz(*channels):
	"""Load FrankerFaceZ emotes for zero or more channels

	If no channels are specified, loads only the global emotes. Otherwise,
	emotes for the named channels (by user ID) will also be loaded.

	Mutates the emote list used by convert_emotes().
	"""
	_load_emotes("FFZ global", "/ffz.json", "https://api.betterttv.net/3/cached/frankerfacez/emotes/global", _xfrm_ffz)
	for channel in channels:
		_load_emotes(channel + " FFZ", "/ffz_%s.json" % channel,
			"https://api.betterttv.net/3/cached/frankerfacez/users/twitch/" + channel, _xfrm_ffz)
	for name, id in old_ffz.items():
		if name not in emote_list:
			emote_list[name] = "https://cdn.betterttv.net/frankerfacez_emote/%s/1" % id

def convert_emotes(msg):
	emotes = get_emote_list()
	words = msg.split()
	for i, word in enumerate(words):
		if "_" in word:
			base, tag = word.split("_", 1)
			if base in emotes and len(tag) == 2:
				words[i] = '![%s](%s "%s")' % (word, emotes[base].replace("/1.0", "_" + tag + "/1.0"), word)
				continue
			# Otherwise fall through. Maybe there are actual emotes with underscores.
		if word not in emotes: continue
		words[i] = '![%s](%s "%s")' % (word, emotes[word], word) # Assumes emote names never contain double quotes
	return " ".join(words)

def validate_translations():
	# Check that the TRANSLATIONS mapping doesn't violate regex rules
	# Basically, this will catch typos like expecting ":)" to match "\\:-?\\(" etc.
	import re
	count = 0
	for trn in TRANSLATIONS.split("\n"):
		if not trn: continue
		pattern, *emotes = trn.split(" ")
		pat = re.compile(pattern) # Validate the RE format itself
		for em in emotes:
			em = em.replace("<", "&lt;").replace(">", "&gt;") # Convert to HTMLish form :(
			m = re.match(pat, em)
			if not m: print("Failed to match:", pattern, em)
			elif m.group(0) != em: print("Failed to consume all:", pattern, em)
		count += 1
	print(count, "emote patterns tested.")

if __name__ == "__main__":
	# To activate BTTV and/or FFZ emotes:
	# load_bttv("devicat"); load_ffz("54212603")
	for msg in sys.argv[1:]:
		print(convert_emotes(msg))
	if len(sys.argv) <= 1:
		validate_translations()
