#!/usr/bin/python3

# from logging import warning as print
from pathlib import Path
import os
import re
import subprocess

MODELINE_PATTERN = \
    r'Modeline\s+"([\w ]+)"\s+[0-9.]+ (\d+) \d+ \d+ \d+ (\d+) \d+ \d+ \d+'

monitor = None
for edid in Path('/sys/devices').glob('**/edid'):
    with open(edid, 'rb') as f:
        content = f.read()
        if len(content) != 0:
            monitor = edid
            break
print("EDID location is %s" % (monitor))
width_mm = None
height_mm = None
width = None
height = None
modeline = dict()
preferred_mode = None
edid = subprocess.check_output("""parse-edid < %s | \
                                  grep -v \
                                  -e Identifier \
                                  -e ModelName""" % monitor,
                               shell=True,
                               encoding='utf8',
                               stderr=open(os.devnull, 'w'))
print(edid)
for line in edid.split('\n'):
    m = re.search(r'DisplaySize\s+(\d+) (\d+)', line)
    if m:
        width_mm = m.group(1)
        height_mm = m.group(2)
        continue

    m = re.search(r'Option\s+"PreferredMode"\s+"([\w ]+)"', line)
    if m:
        preferred_mode = m.group(1)
        continue

    m = re.search(MODELINE_PATTERN, line)
    if m:
        mode = m.group(1)
        width = m.group(2)
        height = m.group(3)
        modeline[mode] = (width, height)

if preferred_mode and preferred_mode in modeline:
    (width, height) = modeline[preferred_mode]
else:
    (width, height) = modeline["Mode 0"]

print('%s %s %s %s' % (width, height, width_mm, height_mm))
