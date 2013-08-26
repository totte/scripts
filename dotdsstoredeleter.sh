#!/bin/sh

# Recursive deletion of all files named .DS_Store

sudo find . -name .DS_Store -print0 | xargs -0 -r rm

# sudo
# find
# .: path to directory to search
# -name
# .DS_Store
# -print0: separate output files with NUL instead of a newline
# |
# xargs
# -0: separate input files by NUL instead of whitespace
# -r: exit if stdin is empty
# rm
