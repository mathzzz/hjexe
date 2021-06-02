#! /bin/bash.orig 
[ "$HJDEBUG" = 1 ] && set -x

execute() {
	local cnt=0 f=$0
	[ -x $f.raw ] && exec $0.raw "$@"
	while link=$(/bin/readlink.orig $f); do
		let cnt++
		[ ${link:0:1} = / ] || link=${f%/*} 
		f=$link
		[ -x $f.raw ] && exec $f.raw "$@"
		[ $cnt = 8 ] && break;
	done
}

# HJOPEN=make,gcc,ar,
if [[ "$HJOPEN" == *${0##*/}* && -r "/home/${SUDO_USER:-$USER}/${0##*/}.rc" ]]; then
	declare -a args=("$@")
    source "/home/${SUDO_USER:-$USER}/${0##*/}.rc" 
	execute "${args[@]}"
else
	execute "$@"
fi

builtin echo error: $0 "$@" 
builtin read -t 1
builtin exit 1
