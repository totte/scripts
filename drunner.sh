#!/bin/sh
cachedir=${XDG_CACHE_HOME:-"$HOME/.cache"}
if [ -d "$cachedir" ]; then
	cache=$cachedir/dmenu_run
else
	cache=$HOME/.dmenu_cache # if no xdg dir, fall back to dotfile in ~
fi
(
	IFS=:
	if stest -dqr -n "$cache" $PATH; then
		stest -flx $PATH | sort -u | tee "$cache" | dmenu -fn 'Chicago-14:style=Bold' -nb '#000000' -nf '#868686' -sb '#868686' -sf '#ffffff' -h '32' -p '» '
	else
		dmenu -fn 'Chicago-14:style=Bold' -nb '#000000' -nf '#868686' -sb '#868686' -sf '#ffffff' -h '32' -p '» ' < "$cache"
	fi
) | ${SHELL:-"/bin/sh"} &
