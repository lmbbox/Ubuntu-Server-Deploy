# Ubuntu Server Deploy

This script will set the initial configuration settings when deploying from a vmware template.

## Usage

To download the scripts:

	source /etc/lsb-release
	git clone -b $DISTRIB_CODENAME git://github.com/lmbbox/Ubuntu-Server-Deploy.git deploy

To setup the scripts on next login:

	sudo deploy/reset.sh

To manually run the scripts:

	sudo deploy/deploy.sh

## Build VMware Template

Build a new template by following the steps below. This implies you know the basics already.

1. Install Ubuntu with LVM. Set swap size.
2. Install updates.

	apt-get update && apt-get upgrade

3. Install SSH and Git along with any other defaults you want.

	apt-get install ssh openssh-server ntp ntpdate curl git subversion

4. Install Open VM Tools (Server installs with no GUI).

	apt-get install --no-install-recommends linux-headers-virtual open-vm-dkms open-vm-tools

## ToDo

Add options to allow loading of variables from local.d scripts named the same as deploy.d scripts or using conf files.

Add deployment scripts for:

	pound
	varnish
	nginx
	php-cli
	php-fpm
