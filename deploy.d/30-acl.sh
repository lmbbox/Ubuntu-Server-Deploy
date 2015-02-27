#!/bin/bash

echo
echo
echo "Install File Permissions ACLs Ubuntu Server Deployment Script"
echo


# Check that this distribution is Ubuntu
if uname -v | grep -qvi ubuntu
then
	echo "This script is meant for Ubuntu distributions only."
	exit 1
fi


# Check if root
if [[ $UID != 0 ]]
then
	echo "You are not root. This script must be run with root permissions."
	exit 1
fi


# Check Internet Access
if ! ping -c 2 8.8.8.8 > /dev/null
then
	echo "You do not have internet access. This script requires the internet to install packages."
	exit 1
fi


# Filepath
root=$(dirname $(readlink -f $0))


# Confirmation
echo
echo -n "Would you like to install File Permissions ACLs? [y/N] "
read confirm
echo

if [[ ! "$confirm" =~ ^[yY]([eE][sS])?$ ]]
then
	echo "File Permissions ACLs installation cancelled."
	exit 1
fi


# Install File Permissions ACLs
echo "Installing File Permissions ACLs ..."
sudo apt-get -y install acl


# Configure /etc/fstab to use ACL on root partition and remount
sed -Ei 's@(\s/\s*ext.\s*)@\1acl,@' /etc/fstab
mount -o remount /


echo
echo "File Permissions ACLs installation complete."
echo
