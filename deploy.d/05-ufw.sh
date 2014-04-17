#!/bin/bash

echo
echo
echo "Install & Configure Uncomplicated Firewall (UFW)"
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
echo -n "Would you like to install & configure Uncomplicated Firewall? [y/N] "
read confirm
echo

if [[ ! "$confirm" =~ ^[yY]([eE][sS])?$ ]]
then
	echo "Uncomplicated Firewall installation cancelled."
	exit 1
fi


echo
echo "Installing Uncomplicated Firewall ..."
sudo apt-get -y install ufw


echo
echo "Allowing ssh ..."
sudo ufw allow 22

echo
echo "Enabling UFW ..."
sudo ufw enable


echo
echo "Uncomplicated Firewall installation complete."
echo
