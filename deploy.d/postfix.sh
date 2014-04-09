#!/bin/bash


echo "Install Postfix Ubuntu Server Deployment Script"


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


# Install Postfix
echo
echo
echo -n "Would you like to install Postfix? [y/N] "
read confirm
echo

if [[ ! "$confirm" =~ ^[yY]([eE][sS])?$ ]]
then
	echo "Postfix installation cancelled."
	exit 1
fi


# Install Postfix
echo
echo "Installing Postfix ..."
sudo apt-get -y install postfix


echo
echo "Postfix installation complete."
