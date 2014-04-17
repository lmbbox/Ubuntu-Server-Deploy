#!/bin/bash

echo
echo
echo "Install MySQL Ubuntu Server Deployment Script"
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
echo "Securing MySQL Installation ..."
echo

while (true)
do
	echo "Please provide password for root MySQL user: "
	if mysql -u root -p -e "DELETE FROM mysql.user WHERE User=''; DROP DATABASE test; DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'; FLUSH PRIVILEGES;"
	then
		break
	else
		echo
		echo -n "There was a problem. Would you like to try again? [Y/n] "
		read confirm
		echo
		
		if [[ "$confirm" =~ ^[nN][oO]?$ ]]
		then
			break
		fi
	fi
done


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
		echo "Allowing mysql (3306) in UFW ..."
		sudo ufw allow 3306
	fi
fi


echo
echo "MySQL installation complete."
echo
