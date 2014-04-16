#!/bin/bash


echo "Install Webserver Ubuntu Server Deployment Script"


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


# Install Apache & PHP
echo
echo
echo -n "Would you like to install Apache & PHP? [y/N] "
read confirm
echo

if [[ ! "$confirm" =~ ^[yY]([eE][sS])?$ ]]
then
	echo "Webserver installation cancelled."
	exit 1
fi


# Install Apache & PHP
echo "Installing Apache & PHP ..."
sudo apt-get -y install mysql-client apache2 php5 libapache2-mod-php5 php5-mysql php5-curl php5-gd php5-idn php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl
echo
echo "Activating Apache modules"
sudo a2enmod ssl
sudo a2enmod rewrite
sudo a2enmod suexec
sudo a2enmod include
sudo a2enmod expires
sudo a2enmod headers


# Replace httpd.conf with custom one
echo
echo "Replacing /etc/apache2/httpd.conf"
sudo mv /etc/apache2/httpd.conf /etc/apache2/httpd.conf-dist
sudo cp $root/apache/httpd.conf /etc/apache2/httpd.conf


# Secure Apache configurations
echo
echo "Securing Apache configurations"
sudo sed -i '/^ServerTokens/s/^/#/' /etc/apache2/conf{.d/security,-available/security.conf} 2> /dev/null
sudo sed -i '/^#ServerTokens Minimal/i ServerTokens Prod' /etc/apache2/conf{.d/security,-available/security.conf} 2> /dev/null
sudo sed -i '/^ServerSignature/s/^/#/' /etc/apache2/conf.d/security /etc/apache2/conf{.d/security,-available/security.conf} 2> /dev/null
sudo sed -i '/^#ServerSignature Off/s/^#//' /etc/apache2/conf{.d/security,-available/security.conf} 2> /dev/null


# Add custom PHP config
echo
echo "Creating /etc/php5/conf.d/custom.ini"
sudo cp $root/php5/conf.d/custom.ini /etc/php5/conf.d/custom.ini


# Fix config files
sudo sed -i 's/^#/;#/g' /etc/php5/conf.d/ming.ini


# Copy example.com site to /srv/www/
echo
echo "Coping example.com site folder"
sudo mkdir -p /srv/www
sudo cp -R $root/apache/example.com/ /srv/www/
sudo chown -R root:root /srv/www/example.com/
sudo chown -R 1000:1000 /srv/www/example.com/htdocs/
sudo cp $root/apache/deploy-site.sh /srv/www/


# Add logrotate config file
echo
echo "Creating /etc/logrotate.d/websites"
sudo cp $root/apache/logrotate /etc/logrotate.d/websites


# Add UFW rules
if [[ -x $(which ufw) ]]
then
	echo
	echo "Allowing http (80) & https (443) in UFW"
	sudo ufw allow 80
	sudo ufw allow 443
fi


sudo service apache2 restart

echo
echo "Webserver installation complete."
