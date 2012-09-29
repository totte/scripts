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
    if ls uali.log &> /dev/null; then
    echo "Log file already exists, deleting it..."
        rm -v uali.log
    fi

    if ls uali.err &> /dev/null; then
        echo "Error log file already exists, deleting it..."
        rm -v uali.err
    fi
}

# Read input
input()
{
    read -p "Enter hostname: " hostname
    read -p "Enter username: " username
    read -p "Enter user e-mail: " useremail
    read -p "Enter device (e.g. /dev/sda): " device
    read -p "Enter keyboard layout (e.g. colemak or sv-latin1): " keyboardlayout
    
    # Infinite loop, only way out (except for Ctrl+C) is to answer yes or no.
    while true; do
        echo "Installing onto a virtual machine? (y/n) "
        read yn
        case $yn in
            [Yy]* ) 
                virtualmachine=1
                break
                ;;
            [Nn]* )
                virtualmachine=0
                break
                ;;
            * )
                echo "Error: Answer (y)es or (n)o."
                ;;
        esac
    done
}

# Create partitions
# Example below: 128 MB for /boot, 16 384 MB for / and the rest for /home
# TODO: Is legacy_boot necessary?
create_partitions()
{
    echo "Creating partitions on $device..."
    {
        parted -s -- "$device" mklabel gpt
        parted -s -- "$device" unit MB mkpart primary 1 129
        parted -s -- "$device" set 1 boot on
        parted -s -- "$device" set 1 legacy_boot on
        parted -s -- "$device" unit MB mkpart primary 129 8321
        parted -s -- "$device" unit MB mkpart primary 8321 -1
    } >> uali.log 2>> uali.err
}

# Format partitions and assign labels
format_partitions()
{
    echo "Creating file systems on $device..."
    {
        mkfs.ext4 "$device"1 -L boot
        mkfs.ext4 "$device"2 -L root
        mkfs.ext4 "$device"3 -L home
    } >> uali.log 2>> uali.err
}

# Mount partitions and add directories
mount_partitions()
{
    echo "Mounting partitions..."
    {
        mount "$device"2 /mnt
        mkdir -pv /mnt/{boot,dev,home,proc,sys,var/{cache/pacman/pkg,lib/pacman/sync,log}}
        mount "$device"1 /mnt/boot
        mount "$device"3 /mnt/home
        mount --bind /dev /mnt/dev
        mount --bind /proc /mnt/proc
        mount --bind /sys /mnt/sys
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
# TODO: Add variable for graphic card drivers
# Dell Precision M4400: NVIDIA, xf86-video-nouveau ('lspci | grep VGA')
install_packages()
{
    echo "Downloading and installing packages..."
    {
        # Keep trying until success
        result=1
        until [ $result -eq 0 ]; do
            pacman --root /mnt --cachedir /mnt/var/cache/pacman/pkg --noconfirm -Sy abs alsa-utils base base-devel git hsetroot lsb-release mesa mpd ncmpc openssh opera pyqt python python-pip qt rxvt-unicode slock sshfs sudo syslinux systemd systemd-arch-units terminus-font tmux vim wget xmobar xmonad xmonad-contrib xorg-server xorg-server-utils xorg-utils xorg-xinit zsh xf86-video-nouveau
            if [ $virtualmachine -eq 1 ]; then
                pacman --root /mnt --cachedir /mnt/var/cache/pacman/pkg --noconfirm -Sy xf86-video-vesa xf86-video-fbdev virtualbox-archlinux-additions
            fi
            result=$?
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
# TODO :%s/localhost/myhostname/g in /etc/hosts
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
        chroot /mnt /sbin/hwclock --systohc --utc
    } >> uali.log 2>> uali.err
}

# Set keyboard layout for console (not X.org)
set_keymap()
{
    echo "Setting keyboard layout..."
    {
        echo "KEYMAP=\"$keyboardlayout\"" > /mnt/etc/vconsole.conf
        echo "FONT=\"Lat2-Terminus16\"" >> /mnt/etc/vconsole.conf
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
        chroot /mnt systemctl enable dhcpcd@eth0.service
    } >> uali.log 2>> uali.err
}

# Create initial ramdisk
create_initial_ramdisk()
{
    echo "Creating initial ramdisk..."
    {
        sed -e 's/\(^MODULES.*\)"$/\1fuse\"/' </mnt/etc/mkinitcpio.conf >/mnt/etc/mkinitcpio.conf.new
        mv /mnt/etc/mkinitcpio.conf.new /mnt/etc/mkinitcpio.conf
        if [ $virtualmachine -eq 1 ]; then
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
        chroot /mnt passwd
    } >> uali.log
}

# Create user
create_user()
{
    echo "Creating user $username and setting password..."
    {
        chroot /mnt useradd -m -g users -G audio,games,log,lp,optical,power,scanner,storage,video,wheel -s /bin/zsh $username
        chroot /mnt passwd $username
    } >> uali.log
}

# Clone the cfg git repository (temporary solution, read-only access, just to get X running)
clone_repositories()
{
    echo "Cloning repositories and linking/copying files..."
    {
        chroot /mnt /bin/zsh <<- END
            dhcpcd
            su $username
                git clone https://totte@bitbucket.org/totte/cfg.git /home/$username/cfg
                rm -frv /home/$username/.bash*
                rm -frv /home/$username/.xinitrc
                ln -sv /home/$username/cfg/.dircolorsrc /home/$username/
                ln -sv /home/$username/cfg/.globalgitignore /home/$username/
                ln -sv /home/$username/cfg/.gvimrc /home/$username/
                ln -sv /home/$username/cfg/.mpdconf /home/$username/
                ln -sv /home/$username/cfg/.tmux.conf /home/$username/
                ln -sv /home/$username/cfg/.toprc /home/$username/
                ln -sv /home/$username/cfg/.vim /home/$username/
                ln -sv /home/$username/cfg/.vimrc /home/$username/
                ln -sv /home/$username/cfg/.Xdefaults /home/$username/
                ln -sv /home/$username/cfg/.xinitrc /home/$username/
                ln -sv /home/$username/cfg/.xmobarrc /home/$username/
                ln -sv /home/$username/cfg/.xmonad /home/$username/
                ln -sv /home/$username/cfg/.zshrc /home/$username/
                mkdir /home/$username/.mpd/playlists
                touch /home/$username/.mpd/{database,log,pid,state,sticker.sql}
                git config --global user.name $username
                git config --global user.email $useremail
                git config --global core.excludesfile ~/.globalgitignore
                mkdir /home/$username/src
                wget -P /home/$username/src/ https://aur.archlinux.org/packages/dm/dmenu-xft-height/dmenu-xft-height.tar.gz
                tar -zxvf /home/$username/src/dmenu-xft-height.tar.gz
                cd /home/$username/src/dmenu-xft-height
                makepkg -s
                xmonad --recompile
                exit
            pacman --noconfirm -U /home/$username/src/dmenu-xft-height/dmenu-xft-height-4.5-1-x86_64.pkg.tar.xz
            killall dhcpcd
            cp -v /home/$username/cfg/syslinux.cfg /boot/syslinux/
            cp -v /home/$username/cfg/boot.png /boot/syslinux/
            ln -sv /home/$username/cfg/.dircolorsrc /root/
            ln -sv /home/$username/cfg/.gvimrc /root/
            ln -sv /home/$username/cfg/.vim /root/
            ln -sv /home/$username/cfg/.vimrc /root/
            ln -sv /home/$username/cfg/.zshrc /root/
            tar -xzvf /home/$username/cfg/fonts.tar.gz
            mkdir -pv /usr/share/fonts/TTF
            mv -v fonts/*.ttf /usr/share/fonts/TTF/
            mv -v fonts/*.ttc /usr/share/fonts/TTF/
            mv -v fonts/*.otf /usr/share/fonts/TTF/
            rm -frv fonts
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
