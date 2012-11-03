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

# Set variables
set_variables()
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
install_packages()
{
    echo `date "+%H:%M:%S"` "Downloading and installing packages..."
    # Keep trying until success
    result=1
    until [ $result -eq 0 ]; do
        pacman --root /mnt --cachedir /mnt/var/cache/pacman/pkg -Sy abs akonadi alsa-utils apache archlinux-themes-slim base base-devel ghc git gnupg hsetroot icedtea-web-java7 jre7-openjdk kde{base-{konq-plugins,konqueror,konsole,workspace},graphics-okular,pim-{akonadiconsole,akregator,console,kaddressbook,kalarm,kmail,knode,kontact,korganizer,ktimetracker},pimlibs,sdk-kate,utils-{kgpg,kwallet}} kid3 konversation ksshaskpass kwalletcli lsb-release mercurial mesa mpd mysql mysql-clients ntp openssh perl-rename php php-apache pkgfile pkgtools pyqt python python-pip qmpdclient qt qtcreator qt-doc smplayer scrot slim slock sshfs sudo syslinux systemd systemd-arch-units transmission-qt ttf-{bitstream-vera,dejavu,droid,inconsolata,liberation,ubuntu-font-family} unclutter unzip vim wget wicd xmobar xmonad xmonad-contrib xorg-{server,server-utils,utils,xinit} zsh xf86-input-synaptics xf86-video-nouveau
        result=$?
    done
}

# Uninstall packages
uninstall_packages()
{
    echo `date "+%H:%M:%S"` "Uninstalling packages..."
    pacman --root /mnt --cachedir /mnt/var/cache/pacman/pkg -Rns initscripts sysvinit sysvinit-tools vi
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
}

# Set locale
set_locale()
{
    echo `date "+%H:%M:%S"` "Setting locale..."
    echo "LANG=en_GB.UTF-8" > /mnt/etc/locale.conf
    echo "LC_COLLATE=C" >> /mnt/etc/locale.conf
    echo "LC_TIME=en_GB.UTF-8" >> /mnt/etc/locale.conf
    echo "en_GB.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    echo "sv_SE.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    chroot /mnt /usr/sbin/locale-gen
}

# Enable daemons
enable_daemons()
{
    echo `date "+%H:%M:%S"` "Enabling daemons..."
    chroot /mnt systemctl enable httpd.service
    chroot /mnt systemctl enable mysqld.service
    chroot /mnt systemctl enable ntpd.service
    chroot /mnt systemctl enable slim.service
    chroot /mnt systemctl enable wicd.service
}

# Create initial ramdisk
create_initial_ramdisk()
{
    echo `date "+%H:%M:%S"` "Creating initial ramdisk..."
    #sed -e 's/\(^MODULES.*\)"$/\1nouveau fuse\"/' </mnt/etc/mkinitcpio.conf >/mnt/etc/mkinitcpio.conf.new
    sed -e 's/\(^MODULES.*\)"$/\1fuse\"/' </mnt/etc/mkinitcpio.conf >/mnt/etc/mkinitcpio.conf.new
    mv /mnt/etc/mkinitcpio.conf.new /mnt/etc/mkinitcpio.conf
    chroot /mnt mkinitcpio -p linux
}

# Configure bootloader
configure_bootloader()
{
    echo `date "+%H:%M:%S"` "Configuring bootloader..."
    chroot /mnt /usr/sbin/syslinux-install_update -im
}

# Create user
create_user()
{
    echo `date "+%H:%M:%S"` "Creating user $username..."
    chroot /mnt useradd -m -g users -G audio,games,log,lp,optical,power,scanner,storage,video,wheel -s /bin/zsh $username
}

# Set passwords
set_passwords()
{
    echo `date "+%H:%M:%S"` "Setting root password..."
    until chroot /mnt passwd; do echo "Try again!"; done
    echo `date "+%H:%M:%S"` "Setting user password..."
    until chroot /mnt passwd $username; do echo "Try again!"; done
}

# Clone the cfg git repository (temporary solution, read-only access, just to get X running)
clone_repositories()
{
    echo `date "+%H:%M:%S"` "Cloning repositories and linking/copying files..."
    chroot /mnt /bin/zsh <<- END
        dhcpcd
        su $username
            mkdir /home/$username/{.config,audiobooks,calendars,code{abs,mote,naturfirman.se,playground,qmpdclient,qvim,scripts,ssia,tott.es},documents,downloads,logs,movies,music,people,pictures,websites}
            git clone https://totte@bitbucket.org/totte/configurations.git /home/$username/.config
            rm -frv /home/$username/.bash*
            rm -frv /home/$username/.xinitrc
            ln -sv /home/$username/.config/.asoundrc /home/$username/
            ln -sv /home/$username/.config/.dircolorsrc /home/$username/
            ln -sv /home/$username/.config/.fonts.conf /home/$username/
            ln -sv /home/$username/.config/.globalgitignore /home/$username/
            ln -sv /home/$username/.config/.gvimrc /home/$username/
            ln -sv /home/$username/.config/.kde4 /home/$username/
            ln -sv /home/$username/.config/.mpdconf /home/$username/
            ln -sv /home/$username/.config/.toprc /home/$username/
            ln -sv /home/$username/.config/.vim /home/$username/
            ln -sv /home/$username/.config/.vimrc /home/$username/
            ln -sv /home/$username/.config/.xinitrc /home/$username/
            ln -sv /home/$username/.config/.xmobarrc /home/$username/
            ln -sv /home/$username/.config/.xmonad /home/$username/
            ln -sv /home/$username/.config/.zshrc /home/$username/
            git config --global user.name $username
            git config --global user.email $useremail
            git config --global core.editor vim
            git config --global core.excludesfile ~/.globalgitignore
            xmonad --recompile
            exit
        killall dhcpcd
        cp -v /home/$username/.config/10-keyboard.conf /etc/X11/xorg.conf.d/
        cp -v /home/$username/.config/10-synaptics.conf /etc/X11/xorg.conf.d/
        cp -v /home/$username/.config/httpd-custom.conf /etc/httpd/conf/extra/
        cp -v /home/$username/.config/httpd-userdir.conf /etc/httpd/conf/extra/
        cp -v /home/$username/.config/httpd.conf /etc/httpd/conf/
        cp -v /home/$username/.config/my.cnf /etc/mysql/
        cp -v /home/$username/.config/php.ini /etc/php/
        cp -v /home/$username/.config/slim.conf /etc/
        cp -v /home/$username/.config/syslinux.cfg /boot/syslinux/
        ln -sv /home/$username/.config/.dircolorsrc /root/
        ln -sv /home/$username/.config/.gvimrc /root/
        ln -sv /home/$username/.config/.vim /root/
        ln -sv /home/$username/.config/.vimrc /root/
        ln -sv /home/$username/.config/.zshrc /root/
        chsh -s /bin/zsh
        echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
        exit
END
}

# Configure MySQL
configure_mysql()
{
    echo `date "+%H:%M:%S"` "Configuring MySQL..."
    chroot /mnt /bin/zsh <<- END
        /usr/bin/systemctl start mysqld
        /usr/bin/mysql_secure_installation
END
}

# Configure Akonadi
# TODO Log into MySQL, create database, user
# TODO Edit ~/.config/akonadi/akonadiserverrc.example (password, filename)
configure_akonadi()
{
    echo `date "+%H:%M:%S"` "Configuring Akonadi..."
}

# Download AUR packages
# TODO Extract them (tar -zxvf)
# TODO Compile them (makepkg -s)
# TODO Install them (pacman -U)
aur_packages()
{
    echo `date "+%H:%M:%S"` "Downloading AUR packages..."
    chroot /mnt /bin/zsh <<- END
        dhcpcd
        su $username
            wget -P /home/$username/code/abs/ https://aur.archlinux.org/packages/al/alsaequal/alsaequal.tar.gz
            wget -P /home/$username/code/abs/ https://aur.archlinux.org/packages/ca/caps/caps.tar.gz
            wget -P /home/$username/code/abs/ https://aur.archlinux.org/packages/vi/vim-qt-git/vim-qt-git.tar.gz
            exit
        killall dhcpcd
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
set_variables
create_partitions
format_partitions
mount_partitions
generate_mirror_list
install_packages
uninstall_packages
copy_pacman_km
generate_fstab
set_hostname
set_timezone
set_keymap
set_locale
enable_daemons
create_initial_ramdisk
configure_bootloader
create_user
set_passwords
clone_repositories
configure_mysql
configure_akonadi
aur_packages
#unmount_partitions

# Done!
echo "Installation completed, reboot to continue."
