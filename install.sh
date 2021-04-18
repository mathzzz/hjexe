#! /home/zjw/.hj/sh
test x$V != x && set -x

read sh sh < $0

die_echo='echo $FUNCTION[0]:$LINENO:'
hjexe=/bin/hjexe
hjhome=$HOME/.hj
ln=$hjhome/ln
sudo=$hjhome/sudo
readlink=$hjhome/readlink

function hj_install() { # $1 must be absolute path
	local realpath=$($readlink -e $1)
	if test -h $1; then
		$sudo $sh -c "$ln -fs $hjexe $1&& $ln -s $realpath $1.raw" ||{ $die_echo; exit;}
	else
		$sudo $sh -c "mv $1 $1.raw && ln -s $hjexe $1" || { $die_echo; exit;}
	fi
	return $?
}

function be_installed() { # $1 must be abosulate path
	local doit=0
	local rawpath=$($readlink -e $1)

	if test -e $1.raw; then
	 	echo $1.raw exists; 
		let doit=doit+1
	fi
	if [ "${rawpath##*/}" = "hjexe" ]; then
		echo $1 is hijacked.
		let doit=doit+1
	fi
	return $((! $doit))
}

if [ "$1" = "-f" ]; then
	force=1
	shift
fi

file_path=$(which $1 2>/dev/null)
if [ "$file_path" = "" ]; then 
	echo Not found $1 in PATH
	exit
fi

## $1 can work
link1=$(readlink $file_path)
if be_installed $file_path; then [ x$force = x ] && exit; fi
hj_install $file_path || exit

echo $(md5sum $file_path) $link1 > $HOME/.hj/$(basename $1).open
echo install.sh $1 ok

