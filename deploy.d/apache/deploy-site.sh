#!/bin/bash


echo "Deploy Site Root Ubuntu Server Deployment Script"


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


# Check if apache2 is installed
if [[ ! -d /etc/apache2 || ! -d /etc/apache2/sites-available || ! -d /etc/apache2/sites-enabled ]]
then
	echo "There is no apache2 configuration directory on this server."
	exit 1
fi


# Filepath
root=$(dirname $(readlink -f $0))


# Check if site root example.com exists
if [[ ! -d $root/example.com || ! -d $root/example.com/htdocs || ! -f $root/example.com/vhost.conf || ! -f $root/example.com/cron ]]
then
	echo "The base site root example does not exist or is missing files."
	exit 1
fi


# Get settings
while true
do
	echo
	echo -n "Please enter a domain: "
	read mydomain
	
	# Confirmation
	echo
	echo "Please confirm your entries:"
	echo "	Domain: $mydomain"
	echo -n "Are these correct? [y/N] "
	read confirm
	echo
	
	if [[ ! "$confirm" =~ ^[yY]([eE][sS])?$ ]]
	then
		echo -n "Would you like to try again? [Y/n] "
		read tryagain

		if [[ ! "$tryagain" =~ ^[nN][oO]?$ ]]
		then
			echo
			echo "Canceled Deployment."
			echo
			exit 1
		fi
		continue
	else
		check=$(dig $mydomain +short | tr -d '[:space:]')
		if [[ ! -n "$check" ]]
		then
			echo "The domain you entered does not resolve to an IP."
			echo -n "Do you still want to continue? [y/N] "
			read confirm
			echo

			if [[ ! "$confirm" =~ ^[yY]([eE][sS])?$ ]]
			then
				echo
				echo "Canceled Deployment."
				echo
				exit 1
			fi
		fi
	fi
	break
done


# Copy base site root and update config files
sudo cp -a $root/example.com $root/$mydomain
sudo sed -i "s/example.com/$mydomain/" $root/$mydomain/vhost.conf $root/$mydomain/cron

# Setup Apache Vhost file and enable site
sudo ln -s $root/$mydomain/vhost.conf /etc/apache2/sites-available/$mydomain.conf
sudo ln -s ../sites-available/$mydomain.conf /etc/apache2/sites-enabled/$mydomain.conf
sudo service apache2 restart

# Link Cron file
sudo ln -s $root/$mydomain/cron /etc/cron.d/${mydomain//./-}


echo
echo -n "Would you like to create a MySQL Database and User? [Y/n] "
read confirm

if [[ ! "$confirm" =~ ^[nN][oO]?$ ]]
then
	echo -n "MySQL Host: "
	read mysqlhost
	echo -n "MySQL Admin User: "
	read mysqluser
	
	# Generate MySQL username, password, and database name
	dbname="$(echo $mydomain | tr -d "[:space:][:punct:]" | head -c 32)"
	dbuser="$(echo $mydomain | tr -d "[:space:][:punct:]" | head -c 16)"
	dbpass="$(cat /dev/urandom | tr -cd "[:alnum:]" | head -c 32)"
	
	mysql -h $mysqlhost -u $mysqluser -p -e "CREATE DATABASE $dbname DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci; GRANT ALL ON $dbname.* TO $dbuser@localhost IDENTIFIED BY '$dbpass'; FLUSH PRIVILEGES;"
	
	echo "host: $mysqlhost" > $root/$mydomain/database.conf
	echo "user: $dbuser" >> $root/$mydomain/database.conf
	echo "pass: $dbpass" >> $root/$mydomain/database.conf
	echo "db: $dbname" >> $root/$mydomain/database.conf
	
	echo
	echo "MySQL Database and User created. Details are in the file $root/$mydomain/database.conf"
fi


echo
echo "Site Root deployment complete."
