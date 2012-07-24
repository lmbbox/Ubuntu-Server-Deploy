#!/bin/bash


echo "Install Drush Ubuntu Server Deployment Script"


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


# Install Drush
echo
echo
echo -n "Would you like to install Drush? [y/N] "
read -n 1 confirm
echo

if [ "$confirm" != "y" ]
then
	echo "Drush installation cancelled."
	exit 1
fi


echo
echo "Installing Drush"
sudo apt-get -y install drush


echo
echo "Drush installation complete."
