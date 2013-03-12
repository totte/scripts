#!/bin/sh

# Arch Linux Installer
# This will automatically install and configure Arch Linux from the
# 2012-09-07 installation media in a specific way for a specific
# machine of mine. It takes about an hour to complete on a 1 Mbit/s
# connection.

# Copyright 2012 Hans "Totte" Tovetjärn, totte@tott.es
# All rights reserved. See LICENSE for more information.

# Tip: iyasefjr cyifmae

# Set variables
set_variables()
{
    hostname="daffodil"
    username="totte"
    useremail="totte@tott.es"
    device="/dev/sda"
    keyboardlayout="colemak"
}

# Create partitions
# 128 MB for /boot, 8 192 MB for /, 4 096 MB for /var, remaining for /home
# TODO: Is legacy_boot necessary?
create_partitions()
{
    echo "Creating partitions on $device..."
    parted -s -- "$device" mklabel gpt
    parted -s -- "$device" unit MB mkpart primary 1 129
    parted -s -- "$device" unit MB mkpart primary 129 8321
    parted -s -- "$device" unit MB mkpart primary 8321 12417
    parted -s -- "$device" unit MB mkpart primary 12417 -1
    parted -s -- "$device" set 1 boot on
    parted -s -- "$device" set 1 legacy_boot on
}

# Format partitions and assign labels
format_partitions()
{
    echo "Creating file systems on $device..."
    mkfs.ext4 "$device"1 -L boot
    mkfs.ext4 "$device"2 -L root
    mkfs.ext4 "$device"3 -L var
    mkfs.ext4 "$device"4 -L home
}

# Mount partitions and create directory structure
mount_partitions()
{
    echo "Mounting partitions..."
    mount "$device"2 /mnt
    mkdir -pv /mnt/{boot,dev,home,proc,sys,var}
    mount "$device"1 /mnt/boot
    mount "$device"3 /mnt/var
    mkdir -pv /mnt/var/{cache/pacman/pkg,lib/pacman/sync,log}
    mount "$device"4 /mnt/home
    mount --bind /dev /mnt/dev
    mount --bind /proc /mnt/proc
    mount --bind /sys /mnt/sys
}

# Generate mirror list
generate_mirror_list()
{
    echo "Generating mirror list..."
    url="http://www.archlinux.org/mirrorlist/?country=SE&protocol=ftp&protocol=http&ip_version=4&use_mirror_status=on"
    wget -qO- "$url" | sed 's/^#Server/Server/g' > /etc/pacman.d/mirrorlist
}

# Install Pacman packages
install_packages()
{
    echo "Downloading and installing packages..."
    # Keep trying until success
    result=1
    until [ $result -eq 0 ]; do
        pacman --root /mnt --cachedir /mnt/var/cache/pacman/pkg -Sy \
            abs \
            acpid \
            akonadi \
            alsa-lib \
            alsa-plugins \
            alsa-utils \
            apache \
            appmenu-qt \
            automoc4 \
            base \
            base-devel \
            bzip2 \
            calligra-meta \
            cantata \
            cmake \
            coreutils \
            ctags \
            curl \
            dbus \
            digikam \
            ffmpeg \
            flac \
            flashplugin \
            fontconfig \
            gcc \
            gdb \
            git \
            gnupg \
            grep \
            gzip \
            iptables \
            ipython \
            kdbg \
            kde-agent \
            kdebase-kdepasswd \
            kdebase-keditbookmarks \
            kdebase-kfind \
            kdebase-konsole \
            kdebase-konq-plugins \
            kdebase-konqueror \
            kdebase-plasma \
            kdebase-runtime \
            kdebase-workspace \
            kdebindings-python \
            kdegraphics-gwenview \
            kdegraphics-ksnapshot \
            kdegraphics-okular \
            kdelibs \
            kdemultimedia-kmix \
            kdenetwork-kget \
            kdepim-akonadiconsole \
            kdepim-akregator \
            kdepim-console \
            kdepim-kaddressbook \
            kdepim-kalarm \
            kdepim-kmail \
            kdepim-kontact \
            kdepim-korganizer \
            kdepim-ktimetracker \
            kdepimlibs \
            kdeplasma-applets-networkmanagement \
            kdesdk-kate \
            kdeutils-kgpg \
            kdeutils-kwallet \
            keychain \
            konversation \
            ksshaskpass \
            kwebkitpart \
            less \
            libkate \
            llvm \
            lsb-release \
            lsof \
            make \
            mesa \
            mpc \
            mpd \
            namcap \
            ntp \
            openssh \
            opera \
            perl-rename \
            phonon \
            phonon-vlc \
            php \
            php-apache \
            php-pgsql \
            pkgfile \
            pkgtools \
            postgresql \
            postgresql-docs \
            postgresql-libs \
            pyqt \
            python \
            python-pip \
            qjson \
            qt4 \
            qtwebkit \
            rsync \
            sed \
            sqlite \
            strigi \
            sudo \
            synaptiks \
            syslinux \
            systemd \
            tar \
            ttf-bitstream-vera \
            ttf-dejavu \
            ttf-droid \
            ttf-inconsolata \
            ttf-liberation \
            ttf-ubuntu-font-family \
            unzip \
            vlc \
            wget \
            which \
            wpa_supplicant \
            x264 \
            xcursor-neutral \
            xorg-server \
            xf86-input-synaptics \
            xf86-video-nouveau \
            xorg-server-utils \
            xorg-utils \
            xorg-xinit \
            zsh
        result=$?
    done
}

# Uninstall Pacman packages
uninstall_packages()
{
    echo "Uninstalling packages..."
    pacman --root /mnt --cachedir /mnt/var/cache/pacman/pkg -Rns vi
}

# Copy Pacman keyring and mirrorlist
copy_pacman_keyring_mirrorlist()
{
    echo "Copying pacman keyring and mirrorlist..."
    cp -av /etc/pacman.d/gnupg /mnt/etc/pacman.d/
    cp -av /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
}

# Install Python packages
install_python_packages()
{
    echo "Installing Python packages..."
    chroot /mnt /bin/zsh <<- END
        dhcpcd
        pip install virtualenv virtualenvwrapper flake8 pytest
        killall dhcpcd
        exit
END
}

# Generate an fstab
generate_fstab()
{
    echo "Generating an fstab..."
    genfstab -pL /mnt >> /mnt/etc/fstab
}

# Set hostname
# TODO :%s/localhost/myhostname/g in /etc/hosts
set_hostname()
{
    echo "Setting hostname..."
    echo $hostname > /mnt/etc/hostname
}

# Set timezone
set_timezone()
{
    echo "Setting timezone..."
    ln -sv /usr/share/zoneinfo/Europe/Stockholm /mnt/etc/localtime
    echo "Europe/Stockholm" > /mnt/etc/timezone
    chroot /mnt /sbin/hwclock --systohc --utc
}

# Set keyboard layout for console (not X.org)
set_keymap()
{
    echo "Setting keyboard layout..."
    echo "KEYMAP=\"$keyboardlayout\"" > /mnt/etc/vconsole.conf
}

# Set locale
set_locale()
{
    echo "Setting locale..."
    echo "LANG=en_GB.UTF-8" > /mnt/etc/locale.conf
    echo "LC_COLLATE=C" >> /mnt/etc/locale.conf
    echo "LC_TIME=en_GB.UTF-8" >> /mnt/etc/locale.conf
    echo "en_GB.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    echo "sv_SE.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    # TODO This line fails with a 404
    chroot /mnt /usr/sbin/locale-gen
}

# Enable daemons
enable_daemons()
{
    echo "Enabling daemons..."
    chroot /mnt systemctl enable acpid.service
    chroot /mnt systemctl enable httpd.service
    chroot /mnt systemctl enable kdm.service
    # TODO This line fails with a 404
    chroot /mnt systemctl enable mysql.service
    # TODO This line fails with a 404
    chroot /mnt systemctl enable NetworkManager.service
    chroot /mnt systemctl enable ntpd.service
    chroot /mnt systemctl enable postgresql.service
}

# Create initial ramdisk
create_initial_ramdisk()
{
    echo "Creating initial ramdisk..."
    #sed -e 's/\(^MODULES.*\)"$/\1nouveau fuse\"/' </mnt/etc/mkinitcpio.conf >/mnt/etc/mkinitcpio.conf.new
    sed -e 's/\(^MODULES.*\)"$/\1fuse\"/' </mnt/etc/mkinitcpio.conf >/mnt/etc/mkinitcpio.conf.new
    mv /mnt/etc/mkinitcpio.conf.new /mnt/etc/mkinitcpio.conf
    chroot /mnt mkinitcpio -p linux
}

# Configure bootloader
configure_bootloader()
{
    echo "Configuring bootloader..."
    chroot /mnt /usr/sbin/syslinux-install_update -im
}

# Set default X cursor theme
set_default_x_cursor_theme()
{
    echo "Setting default X cursor theme..."
    mkdir /mnt/usr/share/icons/default
    # FIXME \n doesn't insert a newline!
    echo "[Icon Theme]\nInherits=Neutra" > /mnt/usr/share/icons/default/index.theme
}

# Create user
create_user()
{
    echo "Creating user $username..."
    chroot /mnt useradd -m -g users -G audio,games,log,lp,optical,power,scanner,storage,video,wheel -s /bin/zsh $username
}

# Set passwords
set_passwords()
{
    echo "Setting root password..."
    until chroot /mnt passwd; do echo "Try again!"; done

    echo "Setting user password..."
    until chroot /mnt passwd $username; do echo "Try again!"; done
}

# Clone the cfg git repository (temporary solution, read-only access, just to get X running)
clone_repositories()
{
    echo "Cloning repositories and linking/copying files..."
    chroot /mnt /bin/zsh <<- END
        dhcpcd
        su $username
            mkdir -p /home/$username/{.config,audiobooks,binaries,calendars,code/{abs,documentation,keybindings,playground,qvim,scripts,tott.es,trunk},documents,downloads,logs,movies,music/.playlists,people,pictures,websites}
            git clone https://totte@bitbucket.org/totte/configurations.git /home/$username/.config
            rm -frv /home/$username/.bash*
            rm -frv /home/$username/.xinitrc
            ln -sv /home/$username/.config/.asoundrc /home/$username/
            ln -sv /home/$username/.config/.detoxrc /home/$username/
            ln -sv /home/$username/.config/.fontconfig /home/$username/
            ln -sv /home/$username/.config/.gitexcludes /home/$username/
            ln -sv /home/$username/.config/.gvimrc /home/$username/
            ln -sv /home/$username/.config/.kde4 /home/$username/
            ln -sv /home/$username/.config/.kderc /home/$username/
            ln -sv /home/$username/.config/.toprc /home/$username/
            ln -sv /home/$username/.config/.vim /home/$username/
            ln -sv /home/$username/.config/.vimrc /home/$username/
            ln -sv /home/$username/.config/.zshrc /home/$username/
            cp -v /home/$username/.config/.gitconfig.example /home/$username/.gitconfig
            exit
        killall dhcpcd
        ln -sv /home/$username/.config/10-keyboard.conf /etc/X11/xorg.conf.d/
        ln -sv /home/$username/.config/httpd-custom.conf /etc/httpd/conf/extra/
        ln -sv /home/$username/.config/httpd-userdir.conf /etc/httpd/conf/extra/
        ln -sv /home/$username/.config/httpd.conf /etc/httpd/conf/
        ln -sv /home/$username/.config/my.cnf /etc/mysql/
        ln -sv /home/$username/.config/php.ini /etc/php/
        ln -sv /home/$username/.config/phy0-led.conf /etc/tmpfiles.d/
        ln -sv /home/$username/.config/syslinux.cfg /boot/syslinux/
        ln -sv /home/$username/.config/.zshrc /root/
        chsh -s /bin/zsh
        echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
        echo "$username ALL=(ALL) NOPASSWD: /bin/umount" >> /etc/sudoers
        exit
END
}

# Download AUR packages
# TODO Extract them (tar -zxvf)
# TODO Compile them (makepkg -cs)
# TODO Install them (pacman -U)
aur_packages()
{
    echo "Downloading AUR packages..."
    chroot /mnt /bin/zsh <<- END
        dhcpcd
        su $username
            wget -P /home/$username/code/abs/ https://aur.archlinux.org/packages/al/alsaequal/alsaequal.tar.gz
            wget -P /home/$username/code/abs/ https://aur.archlinux.org/packages/ca/caps/caps.tar.gz
            wget -P /home/$username/code/abs/ https://aur.archlinux.org/packages/cr/crossover/crossover.tar.gz
            wget -P /home/$username/code/abs/ https://aur.archlinux.org/packages/de/detox/detox.tar.gz
            wget -P /home/$username/code/abs/ https://aur.archlinux.org/packages/tt/ttf-ms-fonts/ttf-ms-fonts.tar.gz
            wget -P /home/$username/code/abs/ https://aur.archlinux.org/packages/ya/yapan/yapan.tar.gz
            wget -P /home/$username/code/abs/ https://aur.archlinux.org/packages/kd/kdeplasma-applets-activeapp/kdeplasma-applets-activeapp.tar.gz
	    wget -P /home/$username/code/abs/ https://aur.archlinux.org/packages/tt/ttf-droid-monovar/ttf-droid-monovar.tar.gz
            exit
        killall dhcpcd
        exit
END
}

# Unmount partitions
unmount_partitions()
{
    echo "Unmounting partitions..."
    # TODO This line fails, device busy - check with lsof
    umount /mnt/{boot,dev,home,proc,sys,}
}

# Run!
set_variables
create_partitions
format_partitions
mount_partitions
generate_mirror_list
install_packages
uninstall_packages
copy_pacman_keyring_mirrorlist
install_python_packages
generate_fstab
set_hostname
set_timezone
set_keymap
set_locale
enable_daemons
create_initial_ramdisk
configure_bootloader
set_default_x_cursor_theme
create_user
set_passwords
clone_repositories
aur_packages
unmount_partitions

# Done!
echo "Installation completed, reboot to continue."

# Once rebooted...

# 1. WLAN
# https://wiki.archlinux.org/index.php/NetworkManager#Disable_current_network_setup
# Stop the network daemon if it's running (wasn't last time...) and then bring
# down the interfaces, whatever their names may be:
# » sudo ip link enp0s25 down
# » sudo ip link wlp12s0 down
# » sudo systemctl enable NetworkManager
# » sudo systemctl start NetworkManager

# 2. SSH and GPG keys
# Restore ssh (~/.ssh) and gpg (~/.gnupg) keys from backup
# » gpg --list-keys
# Example output "... pub 4096R/1234ABCD 2001-01-01 ..."
# » git config --global user.signingkey 1234ABCD

# 3. Finalize configurations
# » cd ~/.config
# » git submodule update --init --recursive && git submodule foreach git pull origin master
# » cp ~/.config/.../foorc.example ~/.config/.../foorc
# » vim ~/.config/.../foorc
# Set UTF-8 as default encoding in Konsole and Kate
# find -name *.example ~/.config/.kde4/share/config/ and rename them without the suffix
# Kontact: KMail, View > Message List > Sorting > By Date/Time && Most Recent on Top
#					Aggregation > Standard Mailing List
#					Theme > Classic
#			 Headers > Fancy Headers
#			 Attachments > Smart
# KDM theme (Caledonia) and settings
# Plasma theme (Caledonia) and settings
#   Upper panel - 32 px high, always visible
#       Application starter menu
#       Current application name
#       Current application menu bar
#       System tray
#       Clock
#   Lower panel - 42 px high, autohide
#       Task manager
# Qt colour scheme (Obsidian Coast)
# KWin window decorations
#   Export window menu bar
#   Window title in bold and centered
#   Minimize, maximize and close buttons on the right
#   Hide title bar when maximized

# 4. Clone project repositories
# » cd ~/code
# » git clone git@bitbucket.org:totte/foo.git foo

# 5. PostgreSQL and Akonadi
# See:
#  https://wiki.archlinux.org/index.php/PostgreSQL
#  https://wiki.archlinux.org/index.php/KDE#Akonadi
# sudo systemd-tmpfiles --create postgresql.conf (no output, what is this supposed to do?)
# sudo mkdir /var/lib/postgres/data
# sudo chown -c postgres:postgres /var/lib/postgres/data
# sudo -i -u postgres
#  initdb -D '/var/lib/postgres/data'
#  exit
# sudo systemctl start postgresql
# sudo systemctl enable postgresql
# sudo -i -u postgres
#  createuser -s -U postgres --interactive
#  Enter name of role to add: totte
#  exit
# createdb akonadi
# akonadictl stop
# rm -rf ~/.local/share/akonadi/db_data
# akonadictl restart
# Basically, get PostgreSQL up and running (do all the troubleshooting steps!), connect to it as (PostgreSQL) root,
# create the akonadi database and user with privileges, flush,
# ~/.config/akonadi/mysql-local.conf already exists, copy akonadiserverrc.example
# in the same directory to akonadiserverrc, enter password and finally, as user
# (NOT sudo) run akonadictl restart/start.

# 6. Apache and ~/websites
# » chmod a+x /home/totte
