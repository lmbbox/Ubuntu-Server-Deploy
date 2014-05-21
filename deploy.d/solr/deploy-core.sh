#!/bin/bash


echo "Deploy Solr Core Ubuntu Server Deployment Script"


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


# Check if solr is installed
if [[ ! -d /usr/local/share/solr || ! -d /usr/local/share/solr/solr ]]
then
	echo "There is no solr install directory on this server."
	exit 1
fi


# Filepath
root=$(dirname $(readlink -f $0))


# Get settings
while true
do
	echo
	echo "Select which existing Solr Cores from which you'd like to clone from."
	echo "Existing Cores Detected: "
	PS3="Please enter your choice (leave blank to see options again): "
	cores="$(cd /usr/local/share/solr/solr/ && ls -d */conf | sed "s/\/conf//") Cancel"
	select core in $cores
	do
		case "$core" in
			'')
				echo "Invalid option. Try another one."
				;;
			Cancel)
				echo
				echo "Canceled Deployment."
				echo
				exit 1
				;;
			*)
				if [[ ! -d /usr/local/share/solr/solr/$core || ! -d /usr/local/share/solr/solr/$core/conf ]]
				then
					echo
					echo "The core you selected is not valid."
					continue
				fi
				break
				;;
		esac
	done
	
	echo
	echo -n "Please enter a name for the new Solr Core: "
	read corename
	
	# Confirmation
	echo
	echo "Please confirm your entries:"
	echo "	Clone From Core: $core"
	echo "	New Core: $corename"
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
		if [[ -d /usr/local/share/solr/solr/$corename ]]
		then
			echo "The core to create '$corename' already exists."
			echo
			echo "Canceled Deployment."
			echo
			exit 1
		fi
	fi
	break
done


## Setup new core
sudo cp -a /usr/local/share/solr/solr/$core /usr/local/share/solr/solr/$corename
sudo sed -i "/<\/cores>/ i \ \ \ \ <core name=\"$corename\" instanceDir=\"$corename\" />" /usr/local/share/solr/solr/solr.xml
sudo service solr restart


echo
echo "Solr Core deployment complete."
