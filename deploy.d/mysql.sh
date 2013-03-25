#!/bin/bash


echo "Install MySQL Ubuntu Server Deployment Script"


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


# Install MySQL
echo
echo
echo -n "Would you like to install MySQL? [y/N] "
read confirm
echo

if [[ ! "$confirm" =~ ^[yY]([eE][sS])?$ ]]
then
	echo "MySQL installation cancelled."
	exit 1
fi


echo
echo "Installing MySQL Client & Server"
sudo apt-get -y install mysql-server mysql-client


echo
echo "MySQL installation complete."
