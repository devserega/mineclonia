#!/usr/bin/env python3

# This is based on the gather_git_credits.py script from the Minetest
# repository. It has been modified to go back six months for active contributors
# (instead of two minor releases) and only take into account the number of
# changes, not the number of commits.

import subprocess
import re
from collections import defaultdict

codefiles = r".lua$"

# the past six months, for "Active Contributors"
SINCE_ACTIVE = "six months ago ago"
# all time, for "Previous Contributors"
SINCE_PREVIOUS = "1970"

CUTOFF_ACTIVE = 150
CUTOFF_PREVIOUS = 1050

def load(since):
	points = defaultdict(int)
	p = subprocess.Popen(["git", "log", "--mailmap", "--pretty=format:%h %aN <%aE>", "--since", since],
		stdout=subprocess.PIPE, universal_newlines=True)
	for line in p.stdout:
		hash, author = line.strip().split(" ", 1)
		n = 0

		p2 = subprocess.Popen(["git", "show", "--numstat", "--pretty=format:", hash],
			stdout=subprocess.PIPE, universal_newlines=True)
		for line in p2.stdout:
			added, deleted, filename = re.split(r"\s+", line.strip(), 2)
			if re.search(codefiles, filename) and added != "-":
				n += int(added)
		p2.wait()

		points[author] += n
	p.wait()

	# Some authors duplicate? Don't add manual workarounds here, edit the .mailmap!
	for author in ("updatepo.sh <script@mt>", "Weblate <42@minetest.ru>"):
		points.pop(author, None)
	return points

points_active = load(SINCE_ACTIVE)
points_prev = load(SINCE_PREVIOUS)

with open("results.txt", "w") as f:
	for author, points in sorted(points_active.items(), key=(lambda e: e[1]), reverse=True):
		if points < CUTOFF_ACTIVE: break
		points_prev.pop(author, None) # active authors don't appear in previous
		f.write("%d\t%s\n" % (points, author))
	f.write('\n---------\n\n')
	once = True
	for author, points in sorted(points_prev.items(), key=(lambda e: e[1]), reverse=True):
		if points < CUTOFF_PREVIOUS and once:
			f.write('\n---------\n\n')
			once = False
		f.write("%d\t%s\n" % (points, author))
