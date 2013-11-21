#! /usr/bin/env python
# -*- coding: utf-8; indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-
#
# Copyright (C) 2013 Shih-Yuan Lee (FourDollars) <fourdollars@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import apt_pkg, re, sys, urllib, urllib2
from apt_inst import DebFile

def get_depends(deb_file):
    deb = DebFile(deb_file)
    control = deb.control.extractdata('control')
    for line in control.split('\n'):
        field = line.split(':', 1)
        if (field[0] == 'Depends'):
            depends = field[1].split(',')
    result = list()
    for depend in depends:
        m = re.match(r"([\w.+-]+)\s+\((\S+)\s+(\S+)\)", depend.strip())
        if m is not None:
            result.append(m.groups())
        else:
            raise Exception('Should not be here.', depend.strip())
    return result

def get_packages(list_file):
    result = dict()
    with open(list_file) as f:
        for line in f:
            m = re.match(r"([\w.+-]+)\s+(\S+)", line)
            if m is not None:
                result[m.group(1)] = m.group(2)
            else:
                raise Exception('Should not be here.', line)
    return result

def check_debs(packages, depends):
    result = dict()
    for name, comparator, version in depends:
        if name not in packages:
            result[name] = version
        else:
            vc = apt_pkg.version_compare(packages[name], version)
            if vc < 0 and comparator == '>=':
                result[name] = version
            else:
                raise Exception('Should not be here.', vc, name, packages[name], comparator, version)
    return result

def reporthook(count, blockSize, totalSize):
    if count * blockSize < totalSize:
        percent = int(count * blockSize * 100 / totalSize)
        sys.stdout.write("\r %s %2d%%" % ('*' * (percent * 75 / 100), percent))
        sys.stdout.flush()
    else:
        print("\r %s %2d%%" % ('*' * 75, 100))

def main():
    apt_pkg.init_system()
    packages = get_packages(sys.argv[1])
    depends = get_depends(sys.argv[2])
    downloads = check_debs(packages, depends)
    for k, v in downloads.items():
        ver = v.split(':')
        if len(ver) > 1:
            v = ver[1]
        source = 'https://launchpad.net/ubuntu/+archive/primary/+files/' + k + '_' + v + '_amd64.deb'
        target = k + '_' + v + '_amd64.deb'
        try:
            url = urllib2.urlopen(source).geturl()
        except urllib2.HTTPError, e:
            if e.code == 404:
                try:
                    source = 'https://launchpad.net/ubuntu/+archive/primary/+files/' + k + '_' + v + '_all.deb'
                    target = k + '_' + v + '_all.deb'
                    url = urllib2.urlopen(source).geturl()
                except urllib2.HTTPError, e:
                    print e.code
                    print e.msg
                    print e.headers
        print("Download from " + url + " ...")
        urllib.urlretrieve(url, target, reporthook)

if __name__ == '__main__':
    main()

# vim:fileencodings=utf-8:expandtab:tabstop=4:shiftwidth=4:softtabstop=4
