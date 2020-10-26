#!/bin/bash
# -*- coding: utf-8; indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-
#
# Copyright (C) 2020 Shih-Yuan Lee (FourDollars) <fourdollars@gmail.com>
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

exec 2>&1
set -euo pipefail
IFS=$'\n\t'

usage()
{
    cat <<ENDLINE
Name:

 $(basename "$0") is a general purpose autopkgtest wrapper that can set up the testbed and run tests on the testbed.

Usage:

 $(basename "$0") [lxc|qemu|vm-ubuntu-cloud] [OPTIONS] {focal,unstable,...}

OPTIONS:

 -h | --help
    Print help manual

 -A | --architecture
    Specify the architecture such as amd64, arm64, ...

 -B | --benchmark
    Measure the time in each major process

 -C | --credentials
    Detect and execute the environment setup script of credentials.

 -d | --debug
    Enable debug mode.

 -F | --flush-cache
    Remove the existing testbed and build a new one.

 -m | --mirror
    Specify the mirror site. Now it only works for qemu testbed.

 -R | --rebuild-testbed
    Rebuild the testbed

 -S | --shell-fail
    Run an interactive shell in the testbed after a failed build, test, or dependency installation.

 -s | --size
    Specify the image size for qemu. It is '12G' by default.

 -t | --test-name
    Run only the given test name (from test control file).
ENDLINE
}

if [ "$#" == 0 ]; then
    usage
    exit
fi

region=$(grep LANG= /etc/default/locale | cut -c 9-10 | tr '[:upper:]' '[:lower:]')
if [ -n "$region" ]; then
    region="$region."
fi
benchmark=0
credentials=0
debug=0
flush_cache=0
rebuild_testbed=0
shell_fail=""
test_name=""

OPTS=$(getopt -o A:,B,C,d,F,h,m:,R,S,s:,t: --long architecture:,benchmark,credentials,debug,flush-cache,help,mirror:,rebuild-testbed,shell-fail,size:,test-name: -n 'run-autopkgtest' -- "$@")
eval set -- "${OPTS}"
while :; do
    case "$1" in
        ('-h'|'--help')
            usage
            exit;;
        ('-A'|'--architecture')
            arch="$2"
            shift 2;;
        ('-B'|'--benchmark')
            benchmark=1
            shift;;
        ('-C'|'--credentials')
            credentials=1
            shift;;
        ('-d'|'--debug')
            debug=1
            shift;;
        ('-F'|'--flush-cache')
            flush_cache=1
            shift;;
        ('-m'|'--mirror')
            mirror="$2"
            shift 2;;
        ('-R'|'--rebuild-testbed')
            rebuild_testbed=1
            shift;;
        ('-S'|'--shell-fail')
            shell_fail="--shell-fail"
            shift;;
        ('-s'|'--size')
            size="$2"
            shift 2;;
        ('-t'|'--test-name')
            test_name="--test-name=$2"
            shift 2;;
        ('--') shift; break ;;
        (*) break ;;
    esac
done

echo "$(basename "$0")" "$@"

# Get root permission
sudo cat /dev/null
# Empty benchmark.log
if [ "$benchmark" = 1 ]; then
    :>benchmark.log
fi
# Make consistent output
export LANG=C

arch="${arch:=$(dpkg --print-architecture)}"
builder="autopkgtest-build-$1"

while :; do
    TMP=$(mktemp -u "$HOME/tmp.XXXXXXXXXX")
    if [ -e "$TMP-auto-setup-environment.sh" ]; then
        continue
    else
        break
    fi
done
posix_shell_script="$TMP-auto-setup-environment.sh"
unset TMP

target=$(basename "$PWD")

case "$1" in
    (lxc|qemu)
        echo "Using '$1' testbed."
        ;;
    (lxd)
        echo "'$1' is not supported yet."
        echo "Please use other builder instead."
        exit 1
        ;;
    (vm-ubuntu-cloud)
        echo "Using '$1' testbed."
        builder="autopkgtest-build$1"
        ;;
    (*)
        echo "'$1' is not supported."
        echo "Please use other builder instead."
        exit 1
        ;;
esac

shift

generate_auto_setup_script()
{
    if [ "$benchmark" = 1 ]; then
        echo "=== generate auto setup script ===" | tee -a benchmark.log
    else
        echo "=== generate auto setup script ==="
    fi
    for cmd in "./autopkgtest-$target-auto" "./bin/autopkgtest-$target-auto" "autopkgtest-$target-auto"; do
        for ssh in ~/.ssh/id_ecdsa ~/.ssh/id_rsa; do
            if command -v "$cmd" >/dev/null && [ -f "$ssh" ]; then
                case "$builder" in
                    (autopkgtest-build-lxc)
                        "$cmd" --ssh "$ssh" > "$posix_shell_script"
                        ;;
                    (*)
                        "$cmd" --ssh "$ssh" --copy "${posix_shell_script}.copy" > "$posix_shell_script"
                        ;;
                esac
                chmod +x "$posix_shell_script"
                break 2
            fi
        done
    done
    # Do some sanity check for auto setup script.
    if [ -f "$posix_shell_script" ]; then
        dash -n "$posix_shell_script"
        shellcheck "$posix_shell_script"
    fi
}

check_testbed()
{
    distro="$1"
    series="$2"
    case "$builder" in
        (autopkgtest-build-lxc)
            sudo lxc-info "autopkgtest-$series-$arch"
            ;;
        (autopkgtest-build-qemu)
            if [ -f "$HOME/$distro-$series-$arch.img" ]; then
                true
            else
                false
            fi
            ;;
        (autopkgtest-buildvm-ubuntu-cloud)
            if [ -f "$HOME/vm-ubuntu-cloud-$series-$arch.img" ]; then
                true
            else
                false
            fi
            ;;
    esac
}

build_testbed()
{
    if [ "$benchmark" = 1 ]; then
        echo "=== build testbed ===" | tee -a benchmark.log
    else
        echo "=== build testbed ==="
    fi
    distro="$1"
    series="$2"
    case "$builder" in
        (autopkgtest-build-lxc)
            sudo "$builder" "$distro" "$series" "$arch"
            ;;
        (autopkgtest-build-qemu)
            sudo "$builder" "$series" "$HOME/$distro-$series-$arch.img" --arch="$arch" --mirror="$mirror" --size="${size:=12G}"
            ;;
        (autopkgtest-buildvm-ubuntu-cloud)
            sudo "$builder" --verbose --mirror "$mirror" --release "vm-ubuntu-cloud-$series-$arch" -r "$series" -a "$arch"
            mv "./autopkgtest-focal-$arch.img" ~/"vm-ubuntu-cloud-$series-$arch.img"
            ;;
    esac
}

run_tests_on_testbed()
{
    if [ "$benchmark" = 1 ]; then
        echo "=== run tests on testbed ===" | tee -a benchmark.log
    else
        echo "=== run tests on testbed ==="
    fi
    distro="$1"
    series="$2"
    shift 2
    summary="$builder-$SHA-$series-summary.log"
    logfile="$builder-$SHA-$series-complete.log"
    outputdir="$builder-$SHA-$series"

    # Remove previous log output folder
    if [ -d "$outputdir" ]; then
        rm -fr "$outputdir"
    fi

    ARGS=("-U" "--quiet" "--summary-file=$summary" "--log-file=$logfile" "--output-dir=$outputdir")
    if [ -f "$posix_shell_script" ]; then
        ARGS+=("--copy=$posix_shell_script:/$(basename "$posix_shell_script")" "--setup-commands=/$(basename "$posix_shell_script")")
    fi
    if [ -n "$test_name" ]; then
        ARGS+=("$test_name")
    fi
    if [ -n "$shell_fail" ]; then
        ARGS+=("$shell_fail")
    fi
    QEMU_ARGS=(-c 4 --ram-size 8192)
    if [ "$debug" = 1 ]; then
        QEMU_ARGS+=(-d)
    fi
    if [ "$(dpkg --print-architecture)" != "$arch" ]; then
        CPU="x86_64"
        case "$arch" in
            (arm64)
                CPU="aarch64"
                QEMU_ARGS+=("--qemu-options=-machine raspi3")
                ;;
            (armhf|armel)
                CPU="arm"
                QEMU_ARGS+=("--qemu-options=-machine raspi2")
                ;;
            (i386)
                CPU="i386"
                QEMU_ARGS+=("--qemu-options=-machine ubuntu")
                ;;
            (*)
                echo "'$arch' is not supported."
                exit 1
                ;;
        esac
        QEMU_ARGS+=("--qemu-command=qemu-system-$CPU")
    fi
    if [ -f "${posix_shell_script}.copy" ]; then
        while read -r line; do
            ARGS+=("--copy=$line")
        done < "${posix_shell_script}.copy"
    fi

    case "$builder" in
        (autopkgtest-build-lxc)
            sudo autopkgtest "${ARGS[@]}" -- lxc "autopkgtest-$series-$arch"
            ;;
        (autopkgtest-build-qemu)
            sudo autopkgtest "${ARGS[@]}" -- qemu "${QEMU_ARGS[@]}" "$HOME/$distro-$series-$arch.img"
            ;;
        (autopkgtest-buildvm-ubuntu-cloud)
            sudo autopkgtest "${ARGS[@]}" -- qemu "${QEMU_ARGS[@]}" "$HOME/vm-ubuntu-cloud-$series-$arch.img"
            ;;
    esac
}

clean_testbed()
{
    if [ "$benchmark" = 1 ]; then
        echo "=== clean testbed ===" | tee -a benchmark.log
    else
        echo "=== clean testbed ==="
    fi
    distro="$1"
    series="$2"
    case "$builder" in
        (autopkgtest-build-lxc)
            sudo lxc-destroy -n "autopkgtest-$series-$arch"
            ;;
        (autopkgtest-build-qemu)
            sudo rm "$HOME/$distro-$series-$arch.img"
            ;;
        (autopkgtest-buildvm-ubuntu-cloud)
            sudo rm "$HOME/vm-ubuntu-cloud-$series-$arch.img"
            ;;
    esac
}

if [ -d .git ]; then
    SHA=$(git rev-parse --short HEAD)
else
    SHA=nogit
fi

cleanup() {
    rm -f "$posix_shell_script" "${posix_shell_script}.copy"
    for series in "${SERIES[@]}"; do
        if command -v ubuntu-distro-info >/dev/null && [[ "$(ubuntu-distro-info --all)" =~ $series ]]; then
            distro=ubuntu
        else
            distro=debian
        fi
        if [ -f "$HOME/$distro-$series-$arch.img.raw" ]; then
            rm -f "$HOME/$distro-$series-$arch.img.raw"
        fi
        for item in "$builder-$SHA-$series-summary.log" "$builder-$SHA-$series-complete.log" "$builder-$SHA-$series"; do
            if [ -e "$item" ]; then
                sudo chown "$USER":"$USER" -R "$item"
            fi
        done
        if [ "$benchmark" = 1 ]; then
            grep -e ^= -e ^real -e ^user -e ^sys benchmark.log
        fi
    done
}
trap cleanup EXIT INT TERM

SERIES=()
for series in "$@"; do
    SERIES+=("$series")
    if command -v ubuntu-distro-info >/dev/null && [[ "$(ubuntu-distro-info --all)" =~ $series ]]; then
        distro=ubuntu
        mirror="${mirror:=http://${region}archive.ubuntu.com/ubuntu}"
    else
        distro=debian
        mirror="${mirror:=http://ftp.${region}debian.org/debian}"
    fi
    if ! check_testbed "$distro" "$series" >/dev/null 2>&1 || [ "$rebuild_testbed" = 1 ]; then
        if [ "$flush_cache" = 1 ]; then
            case "$builder" in
                ('autopkgtest-build-lxc')
                    case "$distro" in
                        (ubuntu)
                            sudo rm -fr "/var/cache/lxc/$series/rootfs-$arch"
                            ;;
                        (debian)
                            sudo rm -fr "/var/cache/lxc/$distro/rootfs-$series-$arch"
                            ;;
                    esac
                    ;;
            esac
        fi
        if check_testbed "$distro" "$series" >/dev/null 2>&1; then
            clean_testbed "$distro" "$series"
        fi
        if [ "$benchmark" = 1 ]; then
            time (build_testbed "$distro" "$series") 2>>benchmark.log
        else
            build_testbed "$distro" "$series"
        fi
    fi
    if [ "$credentials" = 1 ] && [ ! -e "$posix_shell_script" ]; then
        if [ "$benchmark" = 1 ]; then
            time (generate_auto_setup_script) 2>>benchmark.log
        else
            generate_auto_setup_script
        fi
    fi
    if [ "$benchmark" = 1 ]; then
        time (run_tests_on_testbed "$distro" "$series") 2>>benchmark.log
    else
        run_tests_on_testbed "$distro" "$series"
    fi
done

# print summary in the end
for series in "$@"; do
    echo "=== $builder-$SHA-$series-summary.log ==="
    cat "$builder-$SHA-$series-summary.log"
done
