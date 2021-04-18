#! /home/zjw/.hj/sh
echo $0 "$@" >/tmp/log.fifo

f=$0
if test -x $f.raw; then 
	exec $0.raw "$@" 
else
	link=$(readlink $f)	
	while [ "$link" != "" ]; do
		if [ "${link:0:1}" = "/" ]; then
			test -x $link.raw && exec $link.raw "$@"
			f=$link
		else
			test -x ${f%/*}/$link.raw && exec ${f%/*}/$link.raw "$@"
			f=${f%/*}/$link
		fi
		link=$(readlink $f)
	done
fi

echo error: $0 "$@" 
return 1
