#!/bin/bash

echo
echo
echo "Setup Networking Ubuntu Server Deployment Script"
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


# Filepath
root=$(dirname $(readlink -f $0))


# Confirmation
echo
echo -n "Would you like to setup networking? [Y/n] "
read confirm
echo

if [[ "$confirm" =~ ^[nN][oO]?$ ]]
then
	echo "Networking Setup cancelled."
	exit 1
fi


# Shutdown all network interfaces except lo
sudo ifdown -a
sudo ifup lo


# Get settings
while true
do
	echo
	echo -n "Please enter a hostname: "
	read myhostname
	echo -n "Please enter a domain: "
	read mydomain
	echo -n "Please enter an IP: "
	read myip
	echo -n "Please enter a subnet mask: "
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
	echo -n "Are these correct? [y/N] "
	read confirm
	echo
	
	if [[ ! "$confirm" =~ ^[yY]([eE][sS])?$ ]]
	then
		echo -n "Would you like to try again? [Y/n] "
		read tryagain
		
		if [[ "$tryagain" =~ ^[nN][oO]?$ ]]
		then
			echo
			echo "Networking Setup cancelled."
			exit 1
		fi
		continue
	fi
	break
done


# Generate /etc/hostname
echo "Generating /etc/hostname ..."
echo $myhostname | sudo tee /etc/hostname > /dev/null
sudo service hostname start


# Generate /etc/hosts
# hosts.template
# {IP} {HOSTNAME} {DOMAIN} {HOSTNAME}
echo "Generating /etc/hosts ..."
sudo cp $root/network/hosts /etc/hosts
sudo sed -i "s/{IP}/$myip/g" /etc/hosts
sudo sed -i "s/{HOSTNAME}/$myhostname/g" /etc/hosts
sudo sed -i "s/{DOMAIN}/$mydomain/g" /etc/hosts


# Generate /etc/network/interfaces
# interfaces.template
# {IP} {NETMASK} {NETWORK} {BROADCAST} {GATEWAY} {NAMESERVERS} {DOMAIN}
echo "Generating /etc/network/interfaces ..."
sudo cp $root/network/interfaces /etc/network/interfaces
sudo sed -i "s/{IP}/$myip/g" /etc/network/interfaces
sudo sed -i "s/{NETMASK}/$mynetmask/g" /etc/network/interfaces
sudo sed -i "s/{NETWORK}/$mynetwork/g" /etc/network/interfaces
sudo sed -i "s/{BROADCAST}/$mybroadcast/g" /etc/network/interfaces
sudo sed -i "s/{GATEWAY}/$mygateway/g" /etc/network/interfaces
sudo sed -i "s/{NAMESERVERS}/$mynameservers/g" /etc/network/interfaces
sudo sed -i "s/{DOMAIN}/$mydomain/g" /etc/network/interfaces


# Restart networking
echo "Resarting networking ..."
sudo ifdown -a
sudo ifup -a


# Check Internet Access
echo "Checking internet access ..."
if ! ping -c 2 8.8.8.8 > /dev/null
then
	echo
	echo "Internet access could not be verified."
	echo -n "Would you like to setup networking again? [Y/n] "
	read confirm
	echo
	
	if [[ "$confirm" =~ ^[nN][oO]?$ ]]
	then
		echo "Networking Setup cancelled."
		exit 1
	fi
	
	# Run script again
	$0
	exit $?
fi


echo
echo "Networking Setup complete."
echo
