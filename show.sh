#! /bin/bash.orig
[ x$V != x ] && set -x

cd $HOME/.hj/ || exit
for f in *.open; do 
	name=${f%.open}
	fullname=$(which $name 2>/dev/null) 
	[ "$fullname" != "" ] && ls -l $fullname
	rawname=$(which $name.raw 2>/dev/null)
	[ "$rawname" != "" -a -e "$rawname" ] && ls -l $rawname
done
