#! /bin/bash.orig

[ "$HJEXE_DEBUG" = "1" ] && set -x


if test -n "$LOGIN_OK"; then
	fifo=/tmp/log.fifo
	[ ! -e $fifo ] && mkfifo $fifo && chmod a+w $fifo 
else
	fifo=/tmp/log.fifo.txt
	[ ! -f $fifo ] && > $fifo && chmod a+w $fifo
fi

shell_log() {
	if [ "$1" != "-cc" ]; then
		echo "PPID=$PPID;PID=$$; cd $PWD; sh" "$@" >>$fifo
	
	fi	
}

gcc_include_key() {
	for f in "$@"; do 
		let b=${#f}-2; 
		[[ ${f:$b} == .[csSa] ]] && return 0; 
		test "${f/.so}" != "$f" && return 0;
	done
	return 1 
}

declare -A args="$@"
log_open=0
env=""
case ${0##*/} in
	gcc)
#		test -n "$IGNORE_Werror" && args="${@//-Werror }"
	        gcc_include_key "$@" && log_open=1
		;;
	ar|ld)
		log_open=1
		;;

	make)
		unset LS_COLORS
		#env="env=$(sed -z 's/$/\\n/g' /proc/$$/environ);"
		env=$(env)
		log_open=1
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

if [ $log_open = 1 ]; then 
	echo "$(printf "%(%F.%T)T" -1);PPID=$PPID PID=$$;cd $PWD; $0 " >>$fifo
        echo "$@" >>$fifo 
	test ${#env} -gt 0 && echo "${env}"  >>$fifo 
fi


f=$0
if test -x $f.raw; then 
#set -x
	#pargs.c "${@//-Werror/-D_plp_=1}" >>$fifo
	exec $0.raw "${@//-Werror/-D__plp__=1}"
set +x
else
	link=$(readlink $f)	
	let cnt=0
	while [ "$link" != "" ]; do
		let cnt++
		if [ "${link:0:1}" = "/" ]; then
			test -x $link.raw && exec $link.raw "$@"
			=$link
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
