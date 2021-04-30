#! /bin/bash.org
set +x
if test -n "$SSH_CONNECTION"; then
	fifo=/tmp/log.fifo
	[ ! -e $fifo ] && mkfifo $fifo && chmod a+w $fifo 
else
	fifo=/tmp/log.fifo.txt
	[ ! -f $fifo ] && touch $fifo && chmod a+w $fifo
fi

if [ "${0##*/}" = "make" ]; then
	env >>$fifo
fi

if [ "${0##*/}" = "git" -o "${0##*/}" = "curl" ]; then
	export ALL_PROXY=socks5://127.0.0.1:5626
fi


if [ "${0##*/}" = "sh" -o "${0##*/}" = "bash" ]; then
	if [ "${1##*/}" = "configure" ]; then
		echo $PWD\; "$@" >>configure.p
	elif [ "$1" = "-c" ]; then
		echo cd $PWD\; PID=$$\;PPID=$PPID\; sh -c "$2" >>$fifo
	fi	
	exec $0.raw "$@"
fi

echo cd $PWD\; PID=$$\;PPID=$PPID\; cmdline=$(base64 -w 0 /proc/$$/cmdline)\;\; $0 "$@" >>$fifo


f=$0
if test -x $f.raw; then 
	exec $0.raw "$@" 
else
	link=$(readlink $f)	
	let cnt=0
	while [ "$link" != "" ]; do
		let cnt++
		if [ "${link:0:1}" = "/" ]; then
			test -x $link.raw && exec $link.raw "$@"
			f=$link
		else
			test -x ${f%/*}/$link.raw && exec ${f%/*}/$link.raw "$@"
			f=${f%/*}/$link
		fi
		link=$(readlink $f)
		[ "$cnt" = "8" ] && break;
	done
fi

echo error: $0 "$@" 
sleep 1
builtin exit 1