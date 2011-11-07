#!/bin/bash


echo "Ubuntu Server Deployment Script"


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


# Get settings
echo
echo -n "Please enter a hostname: "
read myhostname
echo -n "Please enter a domain: "
read mydomain
echo -n "Please enter an IP: "
read myip
echo -n "Please enter a subnet mask (255.255.255.0): "
read mynetmask
echo -n "Please enter a gateway: "
read mygateway
echo -n "Please enter DNS servers (space separated): "
read mynameservers


# Generate network and broadcast values
l="${myip%.*}"
r="${myip#*.}"
n="${mynetmask%.*}"
m="${mynetmask#*.}"
mynetwork=$((${myip%%.*}&${mynetmask%%.*})).$((${r%%.*}&${m%%.*})).$((${l##*.}&${n##*.})).$((${myip##*.}&${mynetmask##*.}))
mybroadcast=$((${myip%%.*} | (255 ^ ${mynetmask%%.*}))).$((${r%%.*} | (255 ^ ${m%%.*}))).$((${l##*.} | (255 ^ ${n##*.}))).$((${myip##*.} | (255 ^ ${mynetmask##*.})))


# Confirmation
echo
echo "Please confirm your entries:"
echo "	Hostname: $myhostname"
echo "	Domain: $mydomain"
echo "	IP Address: $myip"
echo "	Subnet Mask: $mynetmask"
echo "	Network: $mynetwork"
echo "	Broadcast: $mybroadcast"
echo "	Gateway: $mygateway"
echo "	DNS Servers: $mynameservers"
echo -n "Are these correct [y/N]? "
read -n 1 confirm
echo

if [ "$confirm" != "y" ]
then
	echo "Deployment Cancelled."
	exit 1
fi



# Generate /etc/hostname
echo "Generating /etc/hostname"
sudo echo $myhostname > /etc/hostname


# Generate /etc/hosts
# hosts.template
# {IP} {HOSTNAME} {DOMAIN} {HOSTNAME}
echo "Generating /etc/hosts"
sudo cp $root/hosts.template /etc/hosts
sudo sed -i "s/{IP}/$myip/g" /etc/hosts
sudo sed -i "s/{HOSTNAME}/$myhostname/g" /etc/hosts
sudo sed -i "s/{DOMAIN}/$mydomain/g" /etc/hosts


# Generate /etc/resolv.conf
echo "Generating /etc/resolv.conf"
sudo echo "search $mydomain" > /etc/resolv.conf
for nameserver in $mynameservers
do
	sudo echo "nameserver $nameserver" >> /etc/resolv.conf
done


# Generate /etc/network/interfaces
# interfaces.template
# {IP} {NETMASK} {NETWORK} {BROADCAST} {GATEWAY} {NAMESERVERS} {DOMAIN}
echo "Generating /etc/network/interfaces"
sudo cp $root/interfaces.template /etc/network/interfaces
sudo sed -i "s/{IP}/$myip/g" /etc/network/interfaces
sudo sed -i "s/{NETMASK}/$mynetmask/g" /etc/network/interfaces
sudo sed -i "s/{NETWORK}/$mynetwork/g" /etc/network/interfaces
sudo sed -i "s/{BROADCAST}/$mybroadcast/g" /etc/network/interfaces
sudo sed -i "s/{GATEWAY}/$mygateway/g" /etc/network/interfaces
sudo sed -i "s/{NAMESERVERS}/$mynameservers/g" /etc/network/interfaces
sudo sed -i "s/{DOMAIN}/$mydomain/g" /etc/network/interfaces


# Restart networking
sudo /etc/init.d/networking restart


# Update and Upgrade
echo "Updating system"
sudo apt-get update
sudo apt-get -y upgrade




# Extend LVM
echo
echo
echo -n "Would you like to extend the LVM [y/N]? "
read -n 1 confirm
echo

if [ "$confirm" == "y" ]
then
	$root/extendlvm.sh
fi


# Install MySQL
echo
echo
echo -n "Would you like to install MySQL [y/N]? "
read -n 1 confirm
echo

if [ "$confirm" == "y" ]
then
	$root/mysql.sh
fi


# Install Apache & PHP
echo
echo
echo -n "Would you like to install Apache & PHP [y/N]? "
read -n 1 confirm
echo

if [ "$confirm" == "y" ]
then
	$root/webserver.sh
fi


# Set Postfix replay
echo
echo
echo -n "Would you like to use a relay server for Postfix [y/N]? "
read -n 1 confirm
echo

if [ "$confirm" == "y" ]
then
	loop=1
	while $loop
	do
		echo -n "Please enter the relay host (including port if not 25): "
		read relay1
		
		if [ -n "$relay1" ]
		then
			
			
			
		else
			echo -n "You didn't provide a relay host. Do you want to try again [Y/n]? "
			read -n 1 tryagain
			
			if [ "$tryagain" == "n" ]
			then
				loop=0
				cancel=1
			fi
		fi
	done
	
	if [ ! cancel ]
	then
		
		echo -n "Please enter the fallback relay host (including port if not 25). Leave blank if none: "
		read relay2
		
		
		# Edit /etc/postfix/main.cf config
		sudo sed -i "/relayhost.*/d" /etc/postfix/main.cf
		sudo sed -i "/smtp_fallback_relay.*/d" /etc/postfix/main.cf
		sudo echo "relayhost = $relay1" >> /etc/postfix/main.cf
		if [ -n "$relay2" ]
			sudo echo "smtp_fallback_relay = $relay2" >> /etc/postfix/main.cf
		fi
	fi
fi



echo "Removed ~/.bash_login"
rm ~/.bash_login


echo
echo "Deployment complete. Please reboot."

