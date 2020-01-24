#!/usr/bin/python3
# requires system Python and the python3-apt package
import sys
from collections import OrderedDict # Starting with Python 3.7, we could just use vanilla dicts
import apt # ImportError? apt install python3-apt

cache = apt.Cache()
cache.open()
upgrades = []
for pkg in cache:
	if not pkg.is_installed: continue # This is checking upgrades only
	if pkg.candidate == pkg.installed: continue # Already up-to-date
	if pkg.is_auto_installed: continue # Ignore autoinstalled packages
	upgrades.append(pkg)
if not upgrades:
	print("Everything up-to-date.")
	sys.exit(0)

def describe(pkg):
	# Python 3.7 equivalent:
	# return {"Name": pkg.name, "Installed": pkg.installed.version, "Candidate": pkg.candidate.version}
	return OrderedDict((("Name", pkg.name), ("Current", pkg.installed.version), ("Target", pkg.candidate.version)))

desc = [describe(pkg) for pkg in upgrades]
widths = OrderedDict((x, len(x)) for x in desc[0]) # Start with header widths
for d in desc:
	for col in d:
		widths[col] = max(widths[col], len(d[col]))
fmt = "  ".join("%%-%ds" % col for col in widths.values())
print(fmt % tuple(widths))
print("  ".join("-" * col for col in widths.values()))
for d in desc:
	print(fmt % tuple(d.values()))
