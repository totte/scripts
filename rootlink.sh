#!/bin/sh -f

# Creates soft links in /root to files and folders in /home/USER/.config.
# Copyright 2012 Hans Tovetjärn, hans.tovetjarn@gmail.com
# All rights reserved. See LICENSE for more information.

ln -s /home/$1/.config/.dircolorsrc /home/$1/.config/.gvimrc /home/$1/.config/.vim /home/$1/.config/.vimrc /home/$1/.config/.zshrc /root
