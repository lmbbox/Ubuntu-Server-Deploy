#!/bin/bash


echo "Ubuntu Server Deployment Script"


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


# Filepath
root=$(dirname $(readlink -f $0))


# Run Deployment Scripts
echo
echo "Running deployment scripts $root/deploy.d/*.sh"
echo
for f in $root/deploy.d/*.sh
do
	$f
done
echo
echo "Completed running deployment scripts."


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
