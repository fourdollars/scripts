#! /usr/bin/env python3
# -*- coding: utf-8; indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-
#
# Copyright (C) 2014 Shih-Yuan Lee (FourDollars) <fourdollars@gmail.com>
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

from gi.repository import Gdk, Gio, GLib
import math

def check_hidpi_display():
    screen = Gdk.Screen.get_default()
    major = screen.get_primary_monitor()
    width = screen.get_width()
    height = screen.get_height()
    diagonal = math.sqrt(width ** 2 + height ** 2)
    diagonal_mm = math.sqrt(screen.get_monitor_width_mm(major) ** 2 + screen.get_monitor_height_mm(major) ** 2)
    ppi = math.floor(diagonal * 25.4 / diagonal_mm)
    if ppi >= 192 and height >= 1200:
        return (True, screen.get_monitor_plug_name(major))
    else:
        return (False, screen.get_monitor_plug_name(major))

def list_settings(msg=None):
    if msg:
        print(msg)
    for schema in Gio.Settings.list_schemas():
        if schema == 'com.canonical.Unity.Interface' or schema == 'com.ubuntu.user-interface':
            settings = Gio.Settings.new(schema)
            print('[', schema, ']')
            for key in settings.list_keys():
                print(key, '=', settings.get_value(key))

def apply_settings(connector):
    settings = Gio.Settings.new('com.ubuntu.user-interface')
    outputs = settings.get_value('scale-factor').unpack()

    outputs[connector] = 16
    if connector == 'eDP1':
        outputs['eDP-1-0'] = 16
    elif connector == 'eDP-1-0':
        outputs['eDP1'] = 16

    settings.set_value('scale-factor', GLib.Variant('a{si}', outputs))

def main():
    (result, connector) = check_hidpi_display()

    if not result:
        return

    list_settings('Before:')
    apply_settings(connector)
    list_settings('After:')

if __name__ == '__main__':
    main()

# vim:fileencodings=utf-8:expandtab:tabstop=4:shiftwidth=4:softtabstop=4
