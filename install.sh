#! /bin/bash.org
test "$V" != "" && set -x

source conf.rc

read -r sh sh < "$0"
regular_install () { # $1 must be obsolute path
	_file_ok $1;
	test ! -e $1.raw &&	$sudo mv $1 $1.raw || _die
	_file_ok $1.raw
	! _be_hijacked $1 && $sudo $ln -s $hjexe $1 || _die
}

symbolic_link_install_hj () { # $1 must be absolute path
	local link=$1;

	_be_hijacked --long $1 || _die #check
	while ! _be_hijacked $link; do
		test -e $link.raw && _file_ok $link.raw && break;	
		next=$(readlink $link) || _die "$next, $link is empty"
 		! _is_abs_path $next && _dirname $link r1&& next=$r1/$next
		link=$next
	done
	
	if test -e $link.raw && _file_ok $link.raw; then
		if test ! -h $1.raw; then
			$sudo $ln -s $(readlink -e $link.raw) $1.raw|| _die
		fi
	else
		echo $1 is hijacked, but raw file is missing.	
	fi
}

symbolic_link_install () { # $1 must be absolute path
	if _be_hijacked --long "$1"; then
		symbolic_link_install_hj "$1" || _die
		return $?
	fi
	test "${real##*.}" = "raw" && real="${real%.*}"

	if test ! -f $real.raw; then  
		$sudo mv $real $real.raw || _die
		$sudo $ln -s $real.raw $real || _die
	fi

	if test $real.raw != $1.raw; then
		$sudo $ln -s $real.raw $1.raw || _die
	fi
	$sudo mv $1 /tmp/	
	$sudo $ln -s $hjexe $1
}

################# main ##########
test "$1" = "-v" && verbose=1 && shift
test "$1" = "-d" && debug=1 && shift

filepath=$(which $1) || exit 
declare -g real="$(readlink -e $filepath)"
if test "$debug" = "1"; then
	sudo="eval echo \$LINENO:$sudo"
fi

link1=$(readlink $1)
if test -h "$filepath"; then
# (1) sh -> sh2 -> sh3 -> bash 
# (2) sh -> sh2 -> sh3 -> bash -> hjexe
#           sh2.raw -> -> bash.raw
	symbolic_link_install "$filepath" ||_die
else
# bash:
# bash -> hjexe
# bash.raw
	regular_install "$filepath" ||_die
fi
_basename "$1" r 
echo $link1 >$hjhome/$r.open

echo install.sh $1 ok

