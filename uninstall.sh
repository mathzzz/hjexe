#! /bin/bash.orig
test x$V != x && set -x
source conf.rc

################# main ##########
test "$1" = "-v" && verbose=1 && shift
test "$1" = "-d" && debug=1 && shift


filepath=$(which $1) || exit
_be_hijacked --long "$filepath" ||	exit $1 is not hijacked.

test -e $filepath.raw || exit $filepath.raw is missing. 

rawfilelink=$(readlink -e $filepath.raw) || exit "unknow error" 

if test "$debug" = "1"; then
	sudo="eval echo \$LINENO:$sudo"
fi


### uninstall
_file_ok $rawfilelink
$sudo $ln -fs $rawfilelink $filepath
echo uninstall $1 ok
