#!/bin/bash


echo "Install MySQL Ubuntu Server Deployment Script"


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
echo "Installing MySQL Client & Server ..."
sudo apt-get -y install mysql-server mysql-client mysqltuner


echo
echo "Securing MySQL Installation"
echo
echo "Please provide password for root MySQL user: "
mysql -u root -p -e "DELETE FROM mysql.user WHERE User=''; DROP DATABASE test; DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'; FLUSH PRIVILEGES;"


# Add UFW rules
if [[ -x $(which ufw) ]]
then
	echo
	echo -n "Would you like to allow access to MySQL remotely? [y/N] "
	read confirm
	echo
	
	if [[ "$confirm" =~ ^[yY]([eE][sS])?$ ]]
	then
		echo
		echo "Allowing mysql (3306) in UFW"
		sudo ufw allow 3306
	fi
fi


echo
echo "MySQL installation complete."
