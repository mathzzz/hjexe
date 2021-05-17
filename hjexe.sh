#! /bin/bash.orig

[ "$HJEXE_DEBUG" = "1" ] && set -x


if test -n "$LONGIN_OK"; then
	fifo=/tmp/log.fifo
	[ ! -e $fifo ] && mkfifo $fifo && chmod a+w $fifo 
else
	fifo=/tmp/log.fifo.txt
	[ ! -f $fifo ] && touch $fifo && chmod a+w $fifo
fi

shell_log() {
	if [ "$1" != "-cc" ]; then
		echo "PPID=$PPID;PID=$$; cd $PWD; sh $@" >>$fifo
	
	fi	
}

args="$@"
env=""
case ${0##*/} in
	gcc)
		test -n "$IGNORE_Werror" && args="${@//-Werror}"
		;;

	make)
		env="env=$(sed -z 's/$/\\n/g' /proc/$$/environ);"
		;;

	git|curl)
		export ALL_PROXY=socks5://127.0.0.1:5626
		;;

	sh|bash)
		shell_log "$@"
		test -x $0.raw && exec $0.raw "$@"
		;;
	*)
		syslog=syslog
		;;
esac

echo "PPID=$PPID;PID=$$; cd $PWD; $env $0 $@" >>$fifo 


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
		test $cnt = 8  && break;
	done
fi

echo error: $0 "$@" 
sleep 1
builtin exit 1
