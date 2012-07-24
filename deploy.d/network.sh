#!/bin/bash


echo "Setup Networking Ubuntu Server Deployment Script"


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
	read -n 1 confirm
	echo
	
	if [ "$confirm" != "y" ]
	then
		echo -n "Would you like to try again? [Yn] "
		read -n 1 tryagain
		
		if [ "$tryagain" == "n" ]
		then
			echo
			echo "Canceled Networking Setup."
			echo
			exit 1
		fi
		continue
	fi
	break
done


# Generate /etc/hostname
echo "Generating /etc/hostname"
sudo echo $myhostname > /etc/hostname


# Generate /etc/hosts
# hosts.template
# {IP} {HOSTNAME} {DOMAIN} {HOSTNAME}
echo "Generating /etc/hosts"
sudo cp $root/network/hosts /etc/hosts
sudo sed -i "s/{IP}/$myip/g" /etc/hosts
sudo sed -i "s/{HOSTNAME}/$myhostname/g" /etc/hosts
sudo sed -i "s/{DOMAIN}/$mydomain/g" /etc/hosts


# Generate /etc/network/interfaces
# interfaces.template
# {IP} {NETMASK} {NETWORK} {BROADCAST} {GATEWAY} {NAMESERVERS} {DOMAIN}
echo "Generating /etc/network/interfaces"
sudo cp $root/network/interfaces /etc/network/interfaces
sudo sed -i "s/{IP}/$myip/g" /etc/network/interfaces
sudo sed -i "s/{NETMASK}/$mynetmask/g" /etc/network/interfaces
sudo sed -i "s/{NETWORK}/$mynetwork/g" /etc/network/interfaces
sudo sed -i "s/{BROADCAST}/$mybroadcast/g" /etc/network/interfaces
sudo sed -i "s/{GATEWAY}/$mygateway/g" /etc/network/interfaces
sudo sed -i "s/{NAMESERVERS}/$mynameservers/g" /etc/network/interfaces
sudo sed -i "s/{DOMAIN}/$mydomain/g" /etc/network/interfaces


# Restart networking && reload hostname changes
sudo /etc/init.d/networking restart
sudo service hostname start


echo
echo "Networking Setup complete."
