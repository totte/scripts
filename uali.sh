#!/bin/sh -f

# Unattended Arch Linux Installer (UALI)
# This will automatically install and configure Arch Linux from the 2012-08-04 installation media in a specific way for a specific machine of mine. It takes about an hour to complete on a 1 Mbit/s connection.
# Copyright 2012 Hans Tovetjärn, hans.tovetjarn@gmail.com
# All rights reserved. See LICENSE for more information.

# Delete log files if they exist
delete_logs()
{
	if ls uali.log &> /dev/null; then
    	echo "Log file already exists, deleting it..."
		rm -v uali.log
	fi
	
	if ls uali.err &> /dev/null; then
    	echo "Error log file already exists, deleting it..."
		rm -v uali.err
	fi
}

# Input hostname, root password, username and user password
# TODO Hidden password input
# TODO Add device question
# TODO Add virtual machine question
enter_credentials()
{
	read -p "Enter hostname: " hostname

	while [ 1 ]; do
		read -p "Enter root password: " rootpass1
		read -p "...once more: " rootpass2
		if [ "$rootpass1" == "$rootpass2" ]; then
			break;
		else
			echo "The passwords don't match, try again.";
		fi
	done
	
	read -p "Enter user name: " username
	read -p "Enter full name: " realname
	read -p "Enter e-mail address: " email

	while [ 1 ]; do
		read -p "Enter user password: " userpass1
		read -p "...once more: " userpass2
		if [ "$userpass1" == "$userpass2" ]; then
			break;
		else
			echo "The passwords don't match, try again.";
		fi
	done
	
	while [ 1 ]; do
		read -p "Enter ssh passphrase: " sshpass1
		read -p "...once more: " sshpass2
		if [ "$sshpass1" == "$sshpass2" ]; then
			break;
		else
			echo "The passphrases don't match, try again.";
		fi
	done

	# Target device
	DEV=/dev/sda
	
	# Set to 1 if installing on a virtual machine
	VM=1
}

# Create partitions
# TODO Real machine: 128 MB for /boot and the rest for / on the SSD, a bunch of S-ATA 2TB 7200 RPM drives for /home
# Virtual machine: 128 MB for /boot, 8192 MB for / and the rest for /home
create_partitions()
{
	echo "Creating partitions on $DEV..."
	{
		parted -s -- "$DEV" mklabel gpt
		parted -s -- "$DEV" unit MB mkpart primary 1 129
		parted -s -- "$DEV" set 1 boot on
		parted -s -- "$DEV" set 1 legacy_boot on
		parted -s -- "$DEV" unit MB mkpart primary 129 8321
		parted -s -- "$DEV" unit MB mkpart primary 8321 -1
	} >> uali.log 2>> uali.err
}

# Format partitions and assign labels
format_partitions()
{
	echo "Creating file systems on $DEV..."
	{
		mkfs.ext4 "$DEV"1 -L boot
		mkfs.ext4 "$DEV"2 -L root
		mkfs.ext4 "$DEV"3 -L home
	} >> uali.log 2>> uali.err
}

# Mount partitions and add directories
mount_partitions()
{
	echo "Mounting partitions..."
	{
		mount "$DEV"2 /mnt
		mkdir -pv /mnt/{boot,dev,home,proc,sys,var/{log,lib/pacman/sync,cache/pacman/pkg}}
		mount "$DEV"1 /mnt/boot
		mount "$DEV"3 /mnt/home
		mount --bind /dev /mnt/dev
		mount --bind /sys /mnt/sys
		mount --bind /proc /mnt/proc
	} >> uali.log 2>> uali.err
}

# Generate mirror list
generate_mirror_list()
{
	echo "Generating mirror list..."
	{
		url="http://www.archlinux.org/mirrorlist/?country=SE&protocol=ftp&protocol=http&ip_version=4&use_mirror_status=on"
		wget -qO- "$url" | sed 's/^#Server/Server/g' > /etc/pacman.d/mirrorlist
	} >> uali.log 2>> uali.err
}

# Install packages
install_packages()
{
	echo "Downloading and installing packages..."
	{
		# Keep trying until success
		RC=1
		until [ $RC -eq 0 ]; do
			pacman --root /mnt --cachedir /mnt/var/cache/pacman/pkg --noconfirm -Sy abs alsa-utils base base-devel git hsetroot lsb-release mesa openssh pyqt python python-pip qt rxvt-unicode slock sshfs sudo syslinux systemd systemd-arch-units tmux vim xmobar xmonad xmonad-contrib xorg-server xorg-server-utils xorg-utils xorg-xinit zsh
			if [ $VM -eq 1 ]; then
				pacman --root /mnt --cachedir /mnt/var/cache/pacman/pkg --noconfirm -Sy xf86-video-vesa xf86-video-fbdev virtualbox-archlinux-additions
			fi
			RC=$?
		done
	} >> uali.log 2>> uali.err
}

# Copy Pacman keyring and mirrorlist
copy_pacman_km()
{
	echo "Copying pacman keyring and mirrorlist..."
	{
		cp -av /etc/pacman.d/gnupg /mnt/etc/pacman.d/
		cp -av /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
	} >> uali.log 2>> uali.err
}

# Generate an fstab
generate_fstab()
{
	echo "Generating an fstab..."
	{
		genfstab -pL /mnt >> /mnt/etc/fstab
	} >> uali.log 2>> uali.err
}

# Set hostname
set_hostname()
{
	echo "Setting hostname..."
	{
		echo $hostname > /mnt/etc/hostname
	} >> uali.log 2>> uali.err
}

# Set timezone
set_timezone()
{
	echo "Setting timezone..."
	{
		ln -sv /mnt/usr/share/zoneinfo/Europe/Stockholm /mnt/etc/localtime
		echo "Europe/Stockholm" > /mnt/etc/timezone
	} >> uali.log 2>> uali.err
}

# Set keyboard layout
set_keymap()
{
	echo "Setting keyboard layout and console font..."
	{
		echo "KEYMAP=colemak" > /mnt/etc/vconsole.conf
		echo "FONT=ter-116b" >> /mnt/etc/vconsole.conf
		echo "FONT_MAP=8859-1_to_uni" >> /mnt/etc/vconsole.conf
	} >> uali.log 2>> uali.err
}

# Set locale
set_locale()
{
	echo "Setting locale..."
	{
		echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
		echo "LC_COLLATE=C" >> /mnt/etc/locale.conf
		echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
		chroot /mnt /usr/sbin/locale-gen
	} >> uali.log 2>> uali.err
}

# Enable daemons
enable_daemons()
{
	echo "Enabling daemons..."
	{
		chroot /mnt systemctl enable dhcpcd@.service
	} >> uali.log 2>> uali.err
}

# Create initial ramdisk
create_initial_ramdisk()
{
	echo "Creating initial ramdisk..."
	{
		sed -e 's/\(^MODULES.*\)"$/\1fuse\"/' -e 's/\(^HOOKS.*\)"$/\1 consolefont keymap\"/' </mnt/etc/mkinitcpio.conf >/mnt/etc/mkinitcpio.conf.new
		mv /mnt/etc/mkinitcpio.conf.new /mnt/etc/mkinitcpio.conf
		if [ $VM -eq 1 ]; then
			sed -e 's/\(^MODULES.*\)"$/\1 vboxguest vboxsf vboxvideo\"/' </mnt/etc/mkinitcpio.conf >/mnt/etc/mkinitcpio.conf.new
			mv /mnt/etc/mkinitcpio.conf.new /mnt/etc/mkinitcpio.conf
		fi
		chroot /mnt mkinitcpio -p linux
	} >> uali.log 2>> uali.err
}

# Configure bootloader
configure_bootloader()
{
	echo "Configuring bootloader..."
	{
		chroot /mnt /usr/sbin/syslinux-install_update -im
	} >> uali.log 2>> uali.err
}

# Set root password
set_root_password()
{
	echo "Setting root password..."
	{
		chroot /mnt passwd <<- END
		$rootpass1
		$rootpass2
		END
	} >> uali.log 2>> uali.err
}

# Create user
create_user()
{
	echo "Creating user $username..."
	{
		chroot /mnt useradd -m -g users -G audio,games,log,lp,optical,power,scanner,storage,video,wheel -s /bin/zsh $username
		chroot /mnt passwd $username <<- END
		$userpass1
		$userpass2
		END
	} >> uali.log 2>> uali.err
}

# Clone git repositories (temporary solution, read-only access)
clone_repositories()
{
	echo "Cloning repositories and linking/copying files..."
	{
		chroot /mnt /bin/zsh <<- END
			dhcpcd
			su $username
				git clone git@bitbucket.org:totte/bin.git /home/$username/bin
				git clone git@bitbucket.org:totte/cfg.git /home/$username/cfg
				git clone git@bitbucket.org:totte/ref.git /home/$username/ref
				exit
			killall dhcpcd
			cp -v /home/$username/cfg/syslinux.cfg /boot/syslinux/
			cp -v /home/$username/cfg/images/splash.png /boot/syslinux/
			su $username
				rm -frv /home/$username/.bash*
				rm -frv /home/$username/.xinitrc
				ln -sv /home/$username/cfg/.dircolorsrc /home/$username/
				ln -sv /home/$username/cfg/.globalgitignore /home/$username/
				ln -sv /home/$username/cfg/.gvimrc /home/$username/
				ln -sv /home/$username/cfg/.tmux.conf /home/$username/
				ln -sv /home/$username/cfg/.toprc /home/$username/
				ln -sv /home/$username/cfg/.vim /home/$username/
				ln -sv /home/$username/cfg/.vimrc /home/$username/
				ln -sv /home/$username/cfg/.Xdefaults /home/$username/
				ln -sv /home/$username/cfg/.xinitrc /home/$username/
				ln -sv /home/$username/cfg/.xmobarrc /home/$username/
				ln -sv /home/$username/cfg/.xmonad /home/$username/
				ln -sv /home/$username/cfg/.zshrc /home/$username/
				git config --global user.name "$realname"
				git config --global user.email "$email"
				git config --global core.excludesfile ~/.globalgitignore
				ssh-keygen -t rsa -C "$email" <<- SSHEND
					$sshpass1
					$sshpass2
					SSHEND
				ssh-add /home/$username/.ssh/id_rsa
				xmonad --recompile
				exit
			ln -sv /home/$username/cfg/.dircolorsrc /root/
			ln -sv /home/$username/cfg/.gvimrc /root/
			ln -sv /home/$username/cfg/.vim /root/
			ln -sv /home/$username/cfg/.vimrc /root/
			ln -sv /home/$username/cfg/.zshrc /root/
			tar -xzvf /home/$username/cfg/fonts.tar.gz
			mv -v /home/$username/cfg/fonts/*.pcf.gz /usr/share/fonts/local/
			mv -v /home/$username/cfg/fonts/* /usr/share/fonts/TTF/
			chsh -s /bin/zsh
			echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
			exit
		END
	} >> uali.log 2>> uali.err
}

# Unmount partitions
unmount_partitions()
{
	echo "Unmounting partitions..."
	{
		umount /mnt/{boot,dev,home,proc,sys,}
	} >> uali.log 2>> uali.err
}

# Run!
delete_logs
enter_credentials
create_partitions
format_partitions
mount_partitions
generate_mirror_list
install_packages
copy_pacman_km
generate_fstab
set_hostname
set_timezone
set_keymap
set_locale
enable_daemons
create_initial_ramdisk
configure_bootloader
set_root_password
create_user
clone_repositories
unmount_partitions

# Done!
echo "Installation completed, reboot to continue."
