# $4's little scripts collection

## mainline-kernels.sh

 Install the mainline kernels from https://kernel.ubuntu.com/~kernel-ppa/mainline on Ubuntu.

```
$ ./mainline-kernels.sh -h
Usage:
    ./mainline_kernels.sh [options] [versions] ...

Options:
    -h|--help          The manual of this script
    -d|--download-only Download only and not install
    -f|--from NUM      Lower bound of kernel version
    -t|--to   NUM      Upper bound of kernel version
    -l|--list          List available kernel versions
    -r|--remove        Remove mainline kernels
    -u|--update        Update the script itself
```

 https://bit.ly/mainline_kernels

## mkfreedos.sh

 A quick script to make FreeDOS USB stick on Debian/Ubuntu.

> Usage: ./mkfreedos.sh [device node, such as /dev/sdb] [Label Name]

## serveo.sh

 A quick script to set up a SSH reverse tunnel on Debian/Ubuntu.
```
$ wget https://bit.ly/sshportal -O - | bash - # random subdomain name
$ wget https://bit.ly/sshportal -O - | bash /dev/stdin thanos snap fingers # specify the subdomain name
```

> Use https://serveo.net/ to set up a SSH reverse tunnel behind the firewall.
> I wrote [an article](https://medium.com/@fourdollars/how-to-setup-a-temporary-ssh-reverse-tunnel-behind-the-firewall-by-serveo-net-on-debian-ubuntu-4c128bb64387) to explain it.

## vimplug.sh

 A quick script to setup the vim environment.

```
wget https://bit.ly/vimplug -O - | bash -
```
 https://bit.ly/vimplug

> Please backup your own ~/.vimrc before using this script.
