#! /home/zjw/.hj/sh
#! /root/.hj/sh
#! /home/zjw/.hj/sh

### check

[ x$V != x ] && set -x
fullpath=$(which $1)
realpath=$(readlink $fullpath)
rawpath=$(readlink -e $fullpath.raw)

if [ "$fullpath" = "" ]; then 
	echo not found $1 in PATH
	exit
fi

if [ "${realpath##*/}" != "hjexe" ]; then
	echo $fullpath is not hijacked.
	exit 
fi

if [ "$rawpath" = "" ]; then 
	echo Does not exist $fullpath.raw
	exit; 
fi

### uninstall
if [ -h $fullpath.raw ]; then
	read md5 file1 file2 < $HOME/.hj/$(basename $fullpath).open
	[ "$file2" = "" ] && file2=$rawpath
	sudo ln -fs $file2 $fullpath 
	sudo rm -f $fullpath.raw
else
	sudo mv $fullpath.raw $fullpath
fi
		
echo uninstall $1 ok
