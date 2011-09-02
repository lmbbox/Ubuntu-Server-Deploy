#!/bin/bash


echo "Ubuntu Server Deployment Script"


# Check that this distribution is Ubuntu
if grep -qvi ubuntu <<< `uname -v`
then
	echo "This script is meant for Ubuntu distributions only."
	exit 1
fi


# Filepath
root=`basename $0`


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
sleep 5


# update and upgrade
echo "Updating system"
sudo apt-get update
sudo apt-get -y upgrade


echo "Removed ~/.bash_login"
rm ~/.bash_login


echo
echo "Deployment complete. Please reboot."

