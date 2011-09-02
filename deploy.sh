#!/bin/bash

# Check that this distrobution is Ubuntu
if grep -qvi ubuntu <<< `uname -v`
then
	echo "This script is meant for Ubuntu distrobutions only."
	exit 1
fi


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
echo -n "Please enter DNS servers (multiple separated by space): "
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
echo $myhostname > /etc/hostname


# Generate /etc/hosts
# hosts.template
# {IP}    {HOSTNAME}.{DOMAIN}     {HOSTNAME}
cp hosts.template /etc/hosts
sed -i "s/{IP}/$myip/g" /etc/hosts
sed -i "s/{HOSTNAME}/$myhostname/g" /etc/hosts
sed -i "s/{DOMAIN}/$mydomain/g" /etc/hosts


# Generate /etc/resolv.conf
echo "search $mydomain" > /etc/resolv.conf
for nameserver in $mynameservers
do
	echo "nameserver $nameserver" >> /etc/resolv.conf
done


# Generate /etc/network/interfaces
# interfaces.template
# {IP} {NETMASK} {NETWORK} {BROADCAST} {GATEWAY} {NAMESERVERS} {DOMAIN}
cp interfaces.template /etc/network/interfaces
sed -i "s/{IP}/$myip/g" /etc/network/interfaces
sed -i "s/{NETMASK}/$mynetmask/g" /etc/network/interfaces
sed -i "s/{NETWORK}/$mynetwork/g" /etc/network/interfaces
sed -i "s/{BROADCAST}/$mybroadcast/g" /etc/network/interfaces
sed -i "s/{GATEWAY}/$mygateway/g" /etc/network/interfaces
sed -i "s/{NAMESERVERS}/$mynameservers/g" /etc/network/interfaces
sed -i "s/{DOMAIN}/$mydomain/g" /etc/network/interfaces


echo "Deployment complete. Please reboot to see the changes."

