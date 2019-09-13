#!/usr/bin/python3

# from logging import warning as print
from pathlib import Path
import os
import re
import subprocess

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
edid = subprocess.check_output("""edid-decode < %s | \
        grep 'Detailed mode:' -A 2""" % monitor,
        shell=True,
        encoding='utf8',
        stderr=open(os.devnull, 'w'))
print(edid)
for line in edid.split('\n'):
    m = re.search(r'(\d+) mm x (\d+) mm', line)
    if m:
        width_mm = m.group(1)
        height_mm = m.group(2)
        continue

    m = re.search(r'(\d+)\s+\d+\s+\d+\s+\d+\s+hborder\s+\d+', line)
    if m:
        width = m.group(1)
        continue

    m = re.search(r'(\d+)\s+\d+\s+\d+\s+\d+\s+vborder\s+\d+', line)
    if m:
        height = m.group(1)
        continue
    
    if width_mm and height_mm and width and height:
        break

print('%s %s %s %s' % (width, height, width_mm, height_mm))
