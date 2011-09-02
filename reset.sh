#!/bin/bash

# Check that this distribution is Ubuntu
if grep -qvi ubuntu <<< `uname -v`
then
	echo "This script is meant for Ubuntu distributions only."
	exit 1
fi


# Get settings
echo
echo -n "Please enter a hostname: "
read myhostname
echo -n "Please enter a domain: "
read mydomain


# Confirmation
echo
echo "Please confirm your entries:"
echo "	Hostname: $myhostname"
echo "	Domain: $mydomain"
echo -n "Are these correct [y/N]? "
read -n 1 confirm
echo

if [ "$confirm" != "y" ]
then
	echo "Reset Cancelled."
	exit 1
fi



# Generate /etc/hostname
echo "Generating /etc/hostname"
sudo echo $myhostname > /etc/hostname


# Generate /etc/hosts
# hosts.template
# {IP} {HOSTNAME} {DOMAIN} {HOSTNAME}
echo "Generating /etc/hosts"
sudo cat << EOF > /etc/hosts
127.0.0.1	localhost
127.0.0.1	$myhostname.$mydomain	$myhostname

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF


# Generate /etc/resolv.conf
echo "Generating /etc/resolv.conf"
sudo echo "search $mydomain" > /etc/resolv.conf


# Generate /etc/network/interfaces
# interfaces.template
# {IP} {NETMASK} {NETWORK} {BROADCAST} {GATEWAY} {NAMESERVERS} {DOMAIN}
echo "Generating /etc/network/interfaces"
sudo cat << EOF > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback
EOF


echo "Generating ~/.bash_login"
echo "sudo ~/deploy/deploy.sh" > ~/.bash_login


echo
echo "System reset for deployment. Please poweroff."

