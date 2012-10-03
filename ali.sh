#!/bin/sh

# Arch Linux Installer
# This will automatically install and configure Arch Linux from the
# 2012-09-07 installation media in a specific way for a specific
# machine of mine. It takes about an hour to complete on a 1 Mbit/s
# connection.
# Copyright 2012 Hans "Totte" Tovetjärn, totte@tott.es
# All rights reserved. See LICENSE for more information.

# Tip: iyasefjr cyifmae

# Delete log files if they exist
delete_logs()
{
    if ls ali.log &> /dev/null; then
    echo "Log file already exists, deleting it..."
        rm -v ali.log
    fi
}

# Read input
input()
{
    hostname="wraith"
    username="totte"
    useremail="totte@tott.es"
    device="/dev/sda"
    keyboardlayout="colemak"
    #read -p "Enter hostname: " hostname
    #read -p "Enter username: " username
    #read -p "Enter user e-mail: " useremail
    #read -p "Enter device (e.g. /dev/sda): " device
    #read -p "Enter keyboard layout (e.g. colemak or sv-latin1): " keyboardlayout
}

# Create partitions
# Example below: 128 MB for /boot, 16 384 MB for / and the rest for /home
# TODO: Is legacy_boot necessary?
create_partitions()
{
    echo `date "+%H:%M:%S"` "Creating partitions on $device..."
    parted -s -- "$device" mklabel gpt
    parted -s -- "$device" unit MB mkpart primary 1 129
    parted -s -- "$device" set 1 boot on
    parted -s -- "$device" set 1 legacy_boot on
    parted -s -- "$device" unit MB mkpart primary 129 8321
    parted -s -- "$device" unit MB mkpart primary 8321 -1
}


# Format partitions and assign labels
format_partitions()
{
    echo `date "+%H:%M:%S"` "Creating file systems on $device..."
    mkfs.ext4 "$device"1 -L boot
    mkfs.ext4 "$device"2 -L root
    mkfs.ext4 "$device"3 -L home
}


# Mount partitions and add directories
mount_partitions()
{
    echo `date "+%H:%M:%S"` "Mounting partitions..."
    mount "$device"2 /mnt
    mkdir -pv /mnt/{boot,dev,home,proc,sys,var/{cache/pacman/pkg,lib/pacman/sync,log}}
    mount "$device"1 /mnt/boot
    mount "$device"3 /mnt/home
    mount --bind /dev /mnt/dev
    mount --bind /proc /mnt/proc
    mount --bind /sys /mnt/sys
}


# Generate mirror list
generate_mirror_list()
{
    echo `date "+%H:%M:%S"` "Generating mirror list..."
    url="http://www.archlinux.org/mirrorlist/?country=SE&protocol=ftp&protocol=http&ip_version=4&use_mirror_status=on"
    wget -qO- "$url" | sed 's/^#Server/Server/g' > /etc/pacman.d/mirrorlist
}


# Install packages
# TODO: Add variable for graphic card drivers
# Dell Precision M4400: NVIDIA, xf86-video-nouveau ('lspci | grep VGA')
install_packages()
{
    echo `date "+%H:%M:%S"` "Downloading and installing packages..."
    # Keep trying until success
    result=1
    until [ $result -eq 0 ]; do
        pacman --root /mnt --cachedir /mnt/var/cache/pacman/pkg --noconfirm -Sy abs alsa-utils base base-devel git gstreamer0.10 gstreamer0.10-plugins hsetroot kdemultimedia-juk lsb-release mesa openssh opera pyqt python python-pip qt qtfm rxvt-unicode slim slock sshfs sudo syslinux systemd systemd-arch-units terminus-font tmux ttf-droid ttf-inconsolata unclutter vim wget wicd xmobar xmonad xmonad-contrib xorg-server xorg-server-utils xorg-utils xorg-xinit zsh xf86-video-nouveau
        result=$?
    done
}


# Copy Pacman keyring and mirrorlist
copy_pacman_km()
{
    echo `date "+%H:%M:%S"` "Copying pacman keyring and mirrorlist..."
    cp -av /etc/pacman.d/gnupg /mnt/etc/pacman.d/
    cp -av /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
}


# Generate an fstab
generate_fstab()
{
    echo `date "+%H:%M:%S"` "Generating an fstab..."
    genfstab -pL /mnt >> /mnt/etc/fstab
}


# Set hostname
# TODO :%s/localhost/myhostname/g in /etc/hosts
set_hostname()
{
    echo `date "+%H:%M:%S"` "Setting hostname..."
    echo $hostname > /mnt/etc/hostname
}


# Set timezone
set_timezone()
{
    echo `date "+%H:%M:%S"` "Setting timezone..."
    ln -sv /mnt/usr/share/zoneinfo/Europe/Stockholm /mnt/etc/localtime
    echo "Europe/Stockholm" > /mnt/etc/timezone
    chroot /mnt /sbin/hwclock --systohc --utc
}


# Set keyboard layout for console (not X.org)
set_keymap()
{
    echo `date "+%H:%M:%S"` "Setting keyboard layout..."
    echo "KEYMAP=\"$keyboardlayout\"" > /mnt/etc/vconsole.conf
    echo "FONT=\"Lat2-Terminus16\"" >> /mnt/etc/vconsole.conf
}


# Set locale
set_locale()
{
    echo `date "+%H:%M:%S"` "Setting locale..."
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
    echo "LC_COLLATE=C" >> /mnt/etc/locale.conf
    echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    chroot /mnt /usr/sbin/locale-gen
}


# Enable daemons
enable_daemons()
{
    echo `date "+%H:%M:%S"` "Enabling daemons..."
    chroot /mnt systemctl enable wicd.service
    chroot /mnt systemctl enable slim.service
}


# Create initial ramdisk
create_initial_ramdisk()
{
    echo `date "+%H:%M:%S"` "Creating initial ramdisk..."
    sed -e 's/\(^MODULES.*\)"$/\1nouveau fuse\"/' </mnt/etc/mkinitcpio.conf >/mnt/etc/mkinitcpio.conf.new
    mv /mnt/etc/mkinitcpio.conf.new /mnt/etc/mkinitcpio.conf
    chroot /mnt mkinitcpio -p linux
}


# Configure bootloader
configure_bootloader()
{
    echo `date "+%H:%M:%S"` "Configuring bootloader..."
    chroot /mnt /usr/sbin/syslinux-install_update -im
}


# Set root password
set_root_password()
{
    echo `date "+%H:%M:%S"` "Setting root password..."
    chroot /mnt passwd
}


# Create user
create_user()
{
    echo `date "+%H:%M:%S"` "Creating user $username and setting password..."
    chroot /mnt useradd -m -g users -G audio,games,log,lp,optical,power,scanner,storage,video,wheel -s /bin/zsh $username
    chroot /mnt passwd $username
}


# Clone the cfg git repository (temporary solution, read-only access, just to get X running)
clone_repositories()
{
    echo `date "+%H:%M:%S"` "Cloning repositories and linking/copying files..."
    chroot /mnt /bin/zsh <<- END
        dhcpcd
        su $username
            mkdir /home/$username/{bin,cfg,doc,downloads,music,photographs,projects,src}
            git clone https://totte@bitbucket.org/totte/cfg.git /home/$username/cfg
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
            git config --global user.name $username
            git config --global user.email $useremail
            git config --global core.excludesfile ~/.globalgitignore
            wget -P /home/$username/src/ https://aur.archlinux.org/packages/be/bespin-svn/bespin-svn.tar.gz
            wget -P /home/$username/src/ https://aur.archlinux.org/packages/dm/dmenu-xft-height/dmenu-xft-height.tar.gz
            wget -P /home/$username/src/ https://aur.archlinux.org/packages/ha/haskell-strict/haskell-strict.tar.gz
            wget -P /home/$username/src/ https://aur.archlinux.org/packages/ha/haskell-xdg-basedir/haskell-xdg-basedir.tar.gz
            wget -P /home/$username/src/ https://aur.archlinux.org/packages/ye/yeganesh/yeganesh.tar.gz
            xmonad --recompile
            exit
        killall dhcpcd
        cp -v /home/$username/cfg/syslinux.cfg /boot/syslinux/
        cp -v /home/$username/cfg/10-keyboard.conf /etc/X11/xorg.conf.d/
        cp -rv /home/$username/cfg/slim /usr/share/slim/themes/
        cp -v /home/$username/cfg/slim.conf /etc/
        ln -sv /home/$username/cfg/.dircolorsrc /root/
        ln -sv /home/$username/cfg/.gvimrc /root/
        ln -sv /home/$username/cfg/.vim /root/
        ln -sv /home/$username/cfg/.vimrc /root/
        ln -sv /home/$username/cfg/.zshrc /root/
        mkdir -pv /usr/share/fonts/TTF
        cp -v /home/$username/cfg/chicagobold.ttf /usr/share/fonts/TTF/
        chsh -s /bin/zsh
        echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
        exit
END
}


# Unmount partitions
unmount_partitions()
{
    echo `date "+%H:%M:%S"` "Unmounting partitions..."
    umount /mnt/{boot,dev,home,proc,sys,}
}

# Run!
delete_logs
input
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
