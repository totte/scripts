#!/bin/sh

# totte's qvim compilation script

# Define the place for the global (g)vimrc file (/etc/vimrc)
sed -i 's|^.*\(#define SYS_.*VIMRC_FILE.*"\) .*$|\1|' src/feature.h
sed -i 's|^.*\(#define VIMRC_FILE.*"\) .*$|\1|' src/feature.h
(cd src && autoconf)

# What are these for again?
export CFLAGS="-g -O0"
export CXXFLAGS="-g -O0"

# See ./configure --help for all options available
./configure \
--with-compiledby=totte \
--prefix=/usr \
--localstatedir=/var/lib/vim \
--mandir=/usr/share/man \
--with-features=big \
--with-x=yes \
--with-tlib=ncurses \
--disable-netbeans \
--enable-gpm \
--enable-acl \
--enable-multibyte \
--enable-cscope \
--enable-perlinterp \
--enable-python3interp \
--enable-gui=qt \

# Temporary workaround; need to contact upstream
sed -i 's/-D_FORTIFY_SOURCE=2/-D_FORTIFY_SOURCE=1/g' src/auto/config.mk

# Compile it
make

# Rename it to invoke GUI on launch
mv -v src/vim src/qvim
