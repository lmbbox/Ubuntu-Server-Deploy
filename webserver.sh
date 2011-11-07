#!/bin/bash

echo "Install Webserver Ubuntu Server Deployment Script"


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


# Install Apache & PHP
echo "Installing Apache & PHP"
sudo apt-get -y install apache2 php5 libapache2-mod-php5 php5-mysql php5-curl php5-gd php5-idn php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl
echo
echo "Activating Apache modules"
sudo a2enmod ssl
sudo a2enmod rewrite
sudo a2enmod suexec
sudo a2enmod include


# Install Postfix
echo
echo "Installing Postfix"
echo "When asked, just use defaults by pressing Enter."
echo -n "Press Enter to continue ... "
sudo apt-get -y install postfix


# Copy example.com site to /var/www/
echo
echo "Coping example.com site folder"
sudo cp -R $root/example.com/ /var/www/
sudo chown -R root:root /var/www/example.com/
sudo chown -R 1000:www-data /var/www/example.com/htdocs/
sudo chown www-data:root /var/www/example.com/logs/cron.log


# Add logrotate config file
echo
echo "Coping logrotate config file"
sudo cp $root/logrotate.template /etc/logrotate.d/websites


echo
echo "Webserver Installation complete."
