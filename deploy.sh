#!/bin/bash


echo "Ubuntu Server Deployment Script"


# Check that this distribution is Ubuntu
if uname -v | grep -qvi ubuntu
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


# Setup Networking
$root/deploy.d/network.sh


# Check Internet Access
echo
echo "Checking Internet Access ..."
echo
ping -c 5 8.8.8.8
echo

if [ $? != 0 ]
then
	echo "You do not have internet access. The scripts require the internet to install packages."
	exit 1
fi


# Update and Upgrade
echo "Updating system"
sudo apt-get update
sudo apt-get -y upgrade


# Extend LVM
$root/deploy.d/extendlvm.sh

# Install UFW
$root/deploy.d/ufw.sh

# Install MySQL
$root/deploy.d/mysql.sh

# Install Apache & PHP
$root/deploy.d/apache.sh

# Install Drush
$root/deploy.d/drush.sh

# Install Postfix
$root/deploy.d/postfix.sh


# Run Custom Scripts
echo
echo "Running custom scripts $root/local.d/*.sh"
echo
for f in $root/local.d/*.sh
do
	$f
done
echo
echo "Completed running custom scripts."


echo
echo "Removed ~/.bash_login"
rm ~/.bash_login


echo
echo "Deployment complete. Please reboot."
