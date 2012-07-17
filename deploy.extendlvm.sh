#!/bin/bash


echo "Extend LVM Ubuntu Server Deployment Script"


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


# Create partition on empty disk
echo
echo -n "Would you like to partition an empty disk for LVM? [Y/n] "
read -n 1 confirm
echo

if [ "$confirm" != "n" ]
then
	while true
	do
		echo
		disks=$(sudo fdisk -l /dev/sd?)
		echo -e "\nPlease review your available disks for which you would like to partition for LVM.\nBesure that the disk has no existing partitions and is empty.\n\n$disks" | less -FX
		echo
		echo -n "Please enter the device to add to the LVM: "
		read dev
		
		# Check that $dev is a block device and is a root disk that is empty
		if [ ! -b $dev ] || ! grep -qi "Disk $dev" <<< `sudo fdisk -l` || [ $(sudo fdisk -l $dev | grep -i "$dev" | wc -l) != 1 ]
		then
			echo "The device you entered is not a block device or an empty disk."
			echo -n "Would you like to try again? [Yn] "
			read -n 1 tryagain
			
			if [ "$tryagain" == "n" ]
			then
				echo
				echo -n "Do you still want to continue with extending the LVM? [yN] "
				read -n 1 tryagain
				
				if [ "$tryagain" == "y" ]
				then
					echo
					echo "Skipping disk partitioning."
					break
				fi
				
				echo
				echo "Canceled LVM Extension."
				echo
				exit 1
			fi
			continue
		fi
		
		
		# Partition device
		echo
		echo "Partitioning the device $dev ..."
		echo
		sudo fdisk $dev <<EOF
n
p
1


t
8e
w
EOF
		echo
		echo "Partitioning Complete."
		echo
		break
	done
fi


# Get volume group and logical volume to extend
while true
do
	echo
	lvolumes=$(sudo lvdisplay)
	echo -e "\nPlease review your Logical Volumes for which you would like to extend.\nPlease note the LV Name and VG Name values.\n\n$lvolumes" | less -FX
	echo
	echo -n "Please enter the LV Name: "
	read lvname
	echo -n "Please enter the VG Name: "
	read vgname
	
	# Check that $dev is a block device and a partition
	if ! sudo vgdisplay $vgname > /dev/null || ! sudo lvdisplay $lvname > /dev/null
	then
		echo "The values you entered are incorrect."
		echo -n "Would you like to try again? [Yn] "
		read -n 1 tryagain
		
		if [ "$tryagain" == "n" ]
		then
			echo
			echo "Canceled LVM Extension."
			echo
			exit 1
		fi
		continue
	fi
	break
done


# Get partition to add to LVM
while true
do
	echo
	disks=$(sudo fdisk -l /dev/sd?)
	echo -e "\nPlease review your available partitions for which you would like to add to the LVM.\n\n$disks" | less -FX
	echo
	echo -n "Please enter the device to add to the LVM: "
	read dev
	
	# Check that $dev is a block device and a partition
	if [ ! -b $dev ] || grep -qi "Disk $dev" <<< `sudo fdisk -l` || ! grep -qi "$dev" <<< `sudo fdisk -l $dev`
	then
		echo "The device you entered is not a block device or a partition."
		echo -n "Would you like to try again? [Yn] "
		read -n 1 tryagain
		
		if [ "$tryagain" == "n" ]
		then
			echo
			echo "Canceled LVM Extension."
			echo
			exit 1
		fi
		continue
	fi
	break
done


# Add partition to LVM and extend VG and LV
echo
echo "Adding device $dev to LVM ..."
echo
if ! sudo pvcreate $dev
then
	echo
	echo "Could not add device $dev to LVM."
	echo "Canceled LVM Extension."
	echo
	exit 1
fi
echo
echo "Extending LVM Volume Group $vgname ..."
echo
sudo vgextend $vgname $dev
echo
echo "Extending LVM Logical Volume to all available free space in Volume Group ..."
echo
sudo lvextend -l +100%FREE $lvname
echo
echo "Resizing file system on $lvname ..."
echo
sudo resize2fs $lvname


echo
echo "LVM Extension complete."
