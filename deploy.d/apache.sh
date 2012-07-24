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
echo
echo
echo -n "Would you like to install Apache & PHP? [y/N] "
read -n 1 confirm
echo

if [ "$confirm" != "y" ]
then
	echo "Webserver installation cancelled."
	exit 1
fi


# Install Apache & PHP
echo "Installing Apache & PHP"
sudo apt-get -y install mysql-client apache2 php5 libapache2-mod-php5 php5-mysql php5-curl php5-gd php5-idn php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl
echo
echo "Activating Apache modules"
sudo a2enmod ssl
sudo a2enmod rewrite
sudo a2enmod suexec
sudo a2enmod include


# Fix config files
sudo sed -i "s/^#/;#/g" /etc/php5/conf.d/ming.ini


# Copy example.com site to /var/www/
echo
echo "Coping example.com site folder"
sudo cp -R $root/apache/example.com/ /var/www/
sudo chown -R root:root /var/www/example.com/
sudo chown -R 1000:www-data /var/www/example.com/htdocs/


# Add logrotate config file
echo
echo "Coping logrotate config file"
sudo cp $root/apache/logrotate /etc/logrotate.d/websites


echo
echo "Webserver installation complete."
