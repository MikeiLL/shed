# Parse Borderlands 2 savefiles and list all items across all characters
# See https://github.com/gibbed/Gibbed.Borderlands2 for a Windows-only
# program to do way more than this, including actually changing stuff.
# This is much simpler; its purpose is to help you twink items between
# your characters, or more specifically, to find the items that you want
# to twink. It should be able to handle Windows and Linux save files, but
# not save files from consoles (they may be big-endian, and/or use another
# compression algorithm). Currently the path is hard-coded for Linux though.
import hashlib
import os.path
import struct
from dataclasses import dataclass
from pprint import pprint
import lzo # ImportError? pip install python-lzo

CLASSES = { # Some of the classes are oddly named in the save files.
	"Tulip_Mechromancer": "Mechromancer", # Gaige
	"Soldier": "Commando", # Axton
	"Lilac_PlayerClass": "Psycho", # Krieg.... a "lilac"??
	"Mercenary": "Gunzerker", # Salvador
}

class Consumable:
	"""Like a bytes/str object but can be consumed a few bytes/chars at a time"""
	def __init__(self, data):
		self.data = data
		self.eaten = 0
		self.left = len(data)
	def get(self, num):
		"""Destructively read the next num bytes/chars of data"""
		if num > self.left: raise ValueError("Out of data!")
		ret = self.data[self.eaten : self.eaten + num]
		self.eaten += num
		self.left -= num
		return ret
	def __len__(self): return self.left
	def peek(self): return self.data[self.eaten:] # Doubles as "convert to bytes/str"

def decode_tree(bits):
	"""Decode a (sub)tree from the given sequence of bits

	Returns either a length-one bytes, or a tuple of two trees (left
	and right). Consumes either a 1 bit and then eight data bits, or
	a 0 bit and then two subtrees.
	"""
	if bits.get(1) == "1": # Is it a leaf?
		return bytes([int(bits.get(8), 2)])
	# Otherwise, it has subnodes.
	return (decode_tree(bits), decode_tree(bits))
def huffman_decode(data, size):
	bits = Consumable(''.join(format(x, "08b") for x in data))
	root = decode_tree(bits)
	ret = []
	while len(ret) < size:
		cur = root
		while isinstance(cur, tuple):
			cur = cur[bits.get(1) == "1"]
		ret.append(cur)
	residue = bits.peek()
	if len(residue) >= 8: raise ValueError("Too much compressed data - residue " + residue)
	return b''.join(ret)

def get_varint(data):
	"""Parse a protobuf varint out of the given data

	It's like a little-endian version of MIDI's variable-length
	integer. I don't know why Google couldn't just adopt what
	already existed.
	"""
	scale = ret = 0
	byte = 128
	while byte > 127:
		byte = data.get(1)[0]
		ret |= (byte&127) << scale
		scale += 7
	return ret

# Handle protobuf wire types by destructively reading from data
protobuf_decoder = [get_varint] # Type 0 is varint
@protobuf_decoder.append
def protobuf_64bit(data):
	return data.get(8)
@protobuf_decoder.append
def protobuf_length_delimited(data):
	return data.get(get_varint(data))
@protobuf_decoder.append
def protobuf_start_group(data):
	raise Exception("Unimplemented")
@protobuf_decoder.append
def protobuf_end_group(data):
	raise Exception("Unimplemented")
@protobuf_decoder.append
def protobuf_32bit(data):
	return data.get(4)

int32, int64 = object(), object() # Pseudo-types. On decode they become normal integers.

class ProtoBuf:
	# These can be packed into arrays.
	PACKABLE = {int: get_varint, int32: protobuf_decoder[1], int64: protobuf_decoder[5]}

	@staticmethod
	def decode_value(val, typ):
		if isinstance(val, int): return val # Only for varints, which should always be ints
		assert isinstance(val, bytes)
		if isinstance(typ, type) and issubclass(typ, ProtoBuf): return typ.decode_protobuf(val)
		if typ in (int32, int64): return int.from_bytes(val, "little")
		if typ is float: return struct.unpack("<f", val)
		if typ is str: return val.decode("UTF-8")
		if typ is bytes: return val
		if typ in (list, dict): return val # TODO
		raise ValueError("Unrecognized annotation %r" % typ)
	@classmethod
	def decode_protobuf(cls, data):
		fields = list(cls.__dataclass_fields__)
		data = Consumable(data)
		values = {}
		while data:
			idx, wiretype = divmod(get_varint(data), 8)
			field = fields[idx - 1]
			val = protobuf_decoder[wiretype](data)
			typ = cls.__dataclass_fields__[field].type
			if isinstance(typ, list):
				lst = values.setdefault(field, [])
				if typ[0] in cls.PACKABLE and wiretype == 2:
					# Packed integers.
					val = Consumable(val)
					while val:
						lst.append(cls.PACKABLE[typ[0]](val))
				else:
					lst.append(cls.decode_value(val, typ[0]))
			else:
				values[field] = cls.decode_value(val, typ)
		return cls(**values)

# Stub types that are used by SaveFile
SkillData = ResourceData = ItemData = Weapon = MissionPlaythrough = bytes
DLCData = RegionGameStage = WorldDiscovery = WeaponMemento = ItemMemento = bytes
Challenge = OneOffChallenge = Lockout = VehicleSkin = bytes

@dataclass
class Color(ProtoBuf):
	alpha: int
	red: int
	green: int
	blue: int
	def __repr__(self): return "RGBA<%d,%d,%d,%d>" % (self.red, self.green, self.blue, self.alpha)
@dataclass
class UIPreferences(ProtoBuf):
	name: str
	color1: Color
	color2: Color
	color3: Color

@dataclass
class InventorySlots(ProtoBuf):
	backpack: int
	weapons: int
	num_quick_slots_flourished: int # No idea what this is.

@dataclass
class BankSlot(ProtoBuf):
	serial: bytes
	# Yes, that's all there is. Just a serial number. Packaged up in a protobuf.

@dataclass
class PackedItemData(ProtoBuf):
	serial: bytes
	quantity: int
	equipped: int
	mark: int

@dataclass
class PackedWeaponData(ProtoBuf):
	serial: bytes
	quickslot: int
	mark: int
	unknown4: int = 0

@dataclass
class SaveFile(ProtoBuf):
	playerclass: str
	level: int
	exp: int
	general_skill_points: int
	specialist_skill_points: int # No idea what the diff is btwn these
	money: [int] # [money, Eridium, Seraph tokens, unknown, Torgue tokens, then eight more unknowns]
	playthroughs_completed: int
	skills: [SkillData]
	unknown9: [int] = None
	unknown10: [int] = None
	resources: [ResourceData] = None
	items: [ItemData] = None
	inventory_slots: InventorySlots = None
	weapons: [Weapon] = None
	stats: bytes = b"" # ?? Opaque (for now)
	fasttravel: [str] = None
	last_fasttravel: str = ""
	missions: [MissionPlaythrough] = None
	preferences: UIPreferences = None
	savegameid: int = 0
	plotmission: int = 0
	unknown22: int = 0
	codesused: [int] = None
	codes_needing_notifs: [int] = None
	total_play_time: int = 0
	last_save_date: str = ""
	dlc: [DLCData] = None
	unknown28: [str] = None
	region_game_stages: [RegionGameStage] = None
	world_discovery: [WorldDiscovery] = None
	badass_mode: int = 0
	weapon_mementos: [WeaponMemento] = None
	item_mementos: [ItemMemento] = None
	save_guid: bytes = b""
	applied_customizations: [str] = None # Current skins?
	black_market: [int] = None
	active_mission: int = 0
	challenges: [Challenge] = None
	level_challenge_unlocks: [int] = None
	one_off_level_challenges: [OneOffChallenge] = None
	bank: [BankSlot] = None
	challenge_prestiges: int = 0
	lockout_list: [Lockout] = None
	is_dlc_class: int = 0
	dlc_class_package: int = 0
	fully_explored: [str] = None
	unknown47: [bytes] = None
	golden_keys: int = 0 # Number "notified", whatever that means.
	last_playthrough: int = 0
	show_new_playthrough_notif: int = 0
	rcvd_default_weap: int = 0
	queued_training_msgs: [str] = None
	packed_item_data: [PackedItemData] = None
	packed_weapon_data: [PackedWeaponData] = None
	awesome_skill_disabled: int = 0
	max_bank_slots: int = 0 # Might be useful when looking for a place to put stuff
	vehicle_skins: [VehicleSkin] = None
	vehicle_steering_mode: int = 0
	has_played_uvhm: int = 0
	overpower_levels: int = 0
	last_overpower_choice: int = 0

class SaveFileFormatError(Exception): pass

def parse_savefile(fn):
	with open(fn, "rb") as f: data = Consumable(f.read())
	# PC builds, presumably including Linux builds, should be
	# little-endian and LZO-compressed. Some retrievals are
	# forced big-endian, others vary by platform. Dunno why.
	endian = "little"
	hash = data.get(20)
	if hash != hashlib.sha1(data.peek()).digest():
		raise SaveFileFormatError("Hash fails to validate")
	uncompressed_size = int.from_bytes(data.get(4), "big")
	if uncompressed_size > 0x40000:
		raise SaveFileFormatError("TODO: handle chunked decompression")
	data = Consumable(lzo.decompress(data.peek(), False, uncompressed_size))
	if len(data) != uncompressed_size:
		raise SaveFileFormatError("Got wrong amount of data back (%d != %d)" % (len(data), uncompressed_size))
	# Okay. Decompression complete. Now to parse the actual data.
	size = int.from_bytes(data.get(4), "big")
	if size != len(data):
		raise SaveFileFormatError("Size doesn't match remaining bytes - corrupt file? chunked?");
	if data.get(3) != b"WSG":
		raise SaveFileFormatError("Invalid magic number - corrupt file?")
	if int.from_bytes(data.get(4), endian) != 2:
		raise SaveFileFormatError("Unsupported version number (probable corrupt file)")
	crc = int.from_bytes(data.get(4), endian)
	uncomp_size = int.from_bytes(data.get(4), endian) # Gibbed uses a *signed* 32-bit int here
	# For some bizarre reason, the data in here is Huffman-compressed.
	# The whole file has already been LZO-compressed. No point compressing twice!
	# Not sure what the last four bytes are. The end of the compressed sequence
	# finishes off the current byte, and then there are always four more bytes.
	data = huffman_decode(data.peek()[:-4], uncomp_size)
	savefile = SaveFile.decode_protobuf(data)
	cls = savefile.playerclass.split(".")[0][3:] # "GD_??????.blah"
	return "Level %d %s: %s\n%r" % (savefile.level, CLASSES.get(cls, cls), savefile.preferences.name, savefile.lockout_list)

dir = os.path.expanduser("~/.local/share/aspyr-media/borderlands 2/willowgame/savedata")
dir = os.path.join(dir, os.listdir(dir)[0]) # If this bombs, you might not have any saves
for fn in sorted(os.listdir(dir)):
	if not fn.endswith(".sav"): continue
	# if fn != "save000a.sav": continue # Hack: Use the smallest file available
	print(fn, end="... ")
	try: print(parse_savefile(os.path.join(dir, fn)))
	except SaveFileFormatError as e: print(e.args[0])
