#!/bin/zsh -f

# Creates soft links in ~ to files and folders in ~/cfg.
# Copyright 2012 Hans Tovetjärn, hans.tovetjarn@gmail.com
# All rights reserved. See LICENSE for more information.
# Runs on Zsh version 4.3.9.

setopt extendedglob

message=""
kind=""
directory=""

# List files in ~/cfg.
files+=( $HOME/cfg/*~*(README|LICENSE|.git*|*.swp|.DS_Store)(D:t) )

# Determine if a file is a soft link, hard link or if it doesn't exist.
check(){
	if [ -h "$HOME/$i" ]; then
		kind="soft link"
	elif [ -f "$HOME/$i" ]; then
		kind="hard link"
	else
		kind="not"
	fi

	# Is target a directory?
	if [ -d "$HOME/cfg/$i" ]; then
		directory="/"
	else
		directory=""
	fi
}

# Rename existing file (if there is one) and then create a soft link to target file.
link(){
	if [ -e "$HOME/$file" ]; then
		message=$(mv -fv $HOME/$file $HOME/$file.backup; ln -sv $HOME/cfg/$file $HOME/$file)
	else
		message=$(ln -sv $HOME/cfg/$file $HOME/$file)
	fi
}

while :
	do
		clear
		declare -i file_number=1

		# Print out menu.
		echo "dotlink creates soft links in ~ to files and folders in ~/cfg."
		echo "Which file or folder would you like to create a link to?"
		echo "================================================================="
		
		# For every file in the array, determine kind and print them out with a designated number.
		# Also, obsessive formatting.
		for i in $files; do
			check $i
			echo -n "$file_number. "
			if [ ${#file_number} -eq 1 ]; then
				echo -n " "
			fi
			echo -n "$i$directory"
			if [ ${#i} -le 10 ]; then
				echo -n "		"
			else
				echo -n "	"
			fi
			echo "($kind found in ~)"
			file_number=$file_number+1
		done
		echo "Q.  Quit"
		echo "=================================================================="

		# Print message if it is set to something.
		if [[ -n $message ]]; then
			echo "$message\n=================================================================="
		fi
		
		# Prompt.
		echo -ne " » "
		read choice
		
		# Quit?
		if [[ $choice = "q" || $choice = "Q" ]]; then
			break

		# Number between 1 and the number of files?
		elif [ $choice -ge 1 ] && [ $choice -le ${#files[*]} ]; then
			file=${files[choice]}
			link $file

		# Invalid choice.
		else
			message="Invalid choice, select a number between 1 and ${#files[*]} or Q to quit."
		fi
	done
