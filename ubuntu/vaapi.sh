#! /usr/bin/env bash
# -*- coding: utf-8; indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-
#
# Copyright (C) 2015 Shih-Yuan Lee (FourDollars) <fourdollars@gmail.com>
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

PKGS="i965-va-driver gstreamer1.0-vaapi vainfo vlc chromium-browser"

case "$(lsb_release -c -s)" in
	(utopic|vivid)
		MPLAYER=no
		;;
	(*)
		MPLAYER=yes
		;;
esac

sudo add-apt-repository --yes ppa:saiarcot895/chromium-beta

if [ "$MPLAYER" = "yes" ]; then
	sudo add-apt-repository --yes ppa:sander-vangrieken/vaapi
	PKGS="$PKGS mplayer-vaapi"
else
	PKGS="$PKGS mplayer"
fi

sudo apt-get update
sudo apt-get install --yes $PKGS

sudo sed -i 's/CHROMIUM_FLAGS=""/CHROMIUM_FLAGS="--ignore-gpu-blacklist"/' /etc/chromium-browser/default
