#!/bin/bash

echo
echo
echo "Extend LVM Ubuntu Server Deployment Script"
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
echo -n "Would you like to extend the LVM? [y/N] "
read confirm
echo

if [[ ! "$confirm" =~ ^[yY]([eE][sS])?$ ]]
then
	echo "LVM Extension cancelled."
	exit 1
fi


# Rescan SCSI Bus for new devices
echo
echo -n "Would you like to rescan scsi bus for new devices? [y/N] "
read confirm
echo

if [[ "$confirm" =~ ^[yY]([eE][sS])?$ ]]
then
	for f in /sys/class/scsi_host/*/scan
	do
		echo "- - -" > "$f"
	done
fi


# Create partition on empty disk
echo
echo -n "Would you like to partition an empty disk for LVM? [Y/n] "
read confirm
echo

if [[ ! "$confirm" =~ ^[nN][oO]?$ ]]
then
	echo
	echo "Disks Detected: "
	PS3="Please enter your choice (leave blank to see options again): "
	devices="$(ls /dev/sd?) Skip Cancel"
	select dev in $devices
	do
		case "$dev" in
			'')
				echo "Invalid option. Try another one."
				;;
			Cancel)
				echo
				echo "Canceled LVM Extension."
				echo
				exit 1
				;;
			Skip)
				echo
				echo "Skipping disk partitioning."
				break
				;;
			*)
				# Check that $dev is a block device and is a root disk that is empty
				if [ ! -b $dev ] || ! $(sudo fdisk -l 2> /dev/null | grep -qi "Disk $dev") || [ $(sudo fdisk -l $dev 2> /dev/null | grep -i "$dev" | wc -l) != 1 ]
				then
					echo
					echo "The device you selected is not a block device or an empty disk."
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
				# Set $dev to new partition on drive
				dev=$(ls $dev?)
				break
				;;
		esac
	done
fi


# Get partition to add to LVM
# First check if $dev is a valid device that we partitioned
if [ ! -b $dev ] || $(sudo fdisk -l 2> /dev/null | grep -qi "Disk $dev") || ! $(sudo fdisk -l $dev 2> /dev/null | grep -qi "$dev")
then
	echo
	echo "Please review your available partitions for which you would like to add to the LVM."
	echo "Partitions Detected: "
	PS3="Please enter your choice (leave blank to see options again): "
	devices="$(ls /dev/sd??) Cancel"
	select dev in $devices
	do
		case "$dev" in
			'')
				echo "Invalid option. Try another one."
				;;
			Cancel)
				echo
				echo "Canceled LVM Extension."
				echo
				exit 1
				;;
			*)
				if [ ! -b $dev ] || $(sudo fdisk -l 2> /dev/null | grep -qi "Disk $dev") || ! $(sudo fdisk -l $dev 2> /dev/null | grep -qi "$dev")
				then
					echo
					echo "The device you selected is not a block device or a partition."
					continue
				fi
				break
				;;
		esac
	done
fi


# Get volume group and logical volume to extend
echo
echo "Please review your Logical Volumes for which you would like to extend."
echo "Partitions Detected: "
PS3="Please enter your choice (leave blank to see options again): "
lvolumes="$(sudo lvdisplay | awk '/LV Path/{print $3}') Cancel"
select lvname in $lvolumes
do
	case "$lvname" in
		'')
			echo "Invalid option. Try another one."
			;;
		Cancel)
			echo
			echo "Canceled LVM Extension."
			echo
			exit 1
			;;
		*)
			# Get vgname from lvname
			vgname=$(sudo lvdisplay $lvname 2> /dev/null | awk '/VG Name/{print $3}')
			
			# Check that $vgname and $lvname are a valid
			if ! $(sudo vgdisplay $vgname > /dev/null 2>&1) || ! $(sudo lvdisplay $lvname > /dev/null 2>&1)
			then
				echo
				echo "The volume you selected is not valid."
				continue
			fi
			break
			;;
	esac
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
echo
