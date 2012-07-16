#!/bin/bash


echo "Extend LVM Ubuntu Server Deployment Script"


# Check that this distribution is Ubuntu
if grep -qvi ubuntu <<< `uname -v`
then
	echo "This script is meant for Ubuntu distributions only."
	exit 1
fi


# Check if root
if [ $UID != 0 ]
then
	echo "You are not root. This script must be run with root permissions."
	exit 1
fi


# Filepath
root=$(dirname $(readlink -f $0))


echo
sudo fdisk -l
echo


# Get settings
echo
echo -n "Please enter a hostname: "
read myhostname
echo -n "Please enter a domain: "
read mydomain
echo -n "Please enter an IP: "
read myip
echo -n "Please enter a subnet mask (255.255.255.0): "
read mynetmask
echo -n "Please enter a gateway: "
read mygateway
echo -n "Please enter DNS servers (space separated): "
read mynameservers


# Confirmation
echo
echo "Please confirm your entries:"
echo "	Hostname: $myhostname"
echo "	Domain: $mydomain"
echo "	IP Address: $myip"
echo "	Subnet Mask: $mynetmask"
echo "	Network: $mynetwork"
echo "	Broadcast: $mybroadcast"
echo "	Gateway: $mygateway"
echo "	DNS Servers: $mynameservers"
echo -n "Are these correct [y/N]? "
read -n 1 confirm
echo

if [ "$confirm" != "y" ]
then
	echo "Deployment Cancelled."
	exit 1
fi




sudo vgdisplay
sudo lvdisplay


sudo fdisk $dev <<EOF
n
p
1


t
8e
w
EOF

sudo pvcreate $dev
sudo vgextend $lvmvg $dev
sudo lvextend -L +$size $lvmlv
sudo resize2fs $lvmlv



echo
echo "LVM Extension complete."
