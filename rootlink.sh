#!/bin/sh -f

# Creates soft links in /root to files and folders in /home/USER/cfg.
# Copyright 2012 Hans Tovetjärn, hans.tovetjarn@gmail.com
# All rights reserved. See LICENSE for more information.

ln -s /home/$1/cfg/.dircolorsrc /home/$1/cfg/.gvimrc /home/$1/cfg/.vim /home/$1/cfg/.vimrc /home/$1/cfg/.zshrc /root
