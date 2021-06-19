#! /bin/bash.orig 
[ "$HJDEBUG" = 1 ] && set -ex

sudo() { [ $UID = 0 ] && "$@" || command sudo "$@"; }
which () { 
	command which.orig $1 2>/dev/null || for f in ${PATH//:/ }; do 
		test -e $f/$1 && echo $f/$1&& break; 
	done
}


execute() {
	local cnt=0 f=$0
	[ -x $f.raw ] && exec $0.raw "$@"
	while link=$(readlink $f); do
		[ ${link:0:1} = / ] || link=${f%/*}/$link
		f=$link
		[ -x $f.raw ] && exec -a $f $f.raw "$@"
		[ $((cnt++)) = 8 ] && break;
	done
}


main () {
# HJOPEN=make,gcc,ar
    if [[ ( "$HJOPEN" == "ALL" || ",$HJOPEN," == *,${0##*/},* ) && -r "$hjhome/${0##*/}.rc" ]]; then
        declare -a args=("$@")
        source "$hjhome/${0##*/}.rc" 
        execute "${args[@]}"
    fi
    execute "$@"
}

cmdbak() {
    local f;
    test -d $hjhome || mkdir $hjhome
    test -e $hjhome/default || echo 'echo $0: "$@" >&2' > $hjhome/default
    while [ $# != 0 ]; do
        f=$(which $1) || exit
        test -f $f.raw || { sudo mv -i $f $f.raw&& sudo ln -s $f.raw $f; }
        test -f $f.orig || sudo ln $f.raw $f.orig
        shift
    done
}

hjexe_install() {
    local fpath hpath
    cmdbak bash which 
    while [ $# != 0 ]; do 
        f=$1;shift
        [ "${f: -4}" = ".raw" ] && continue;
        fpath=$(which $f)|| continue;
        [ -e $fpath.raw ] || sudo mv $fpath $fpath.raw 
        hpath=$(readlink $fpath) || sudo ln -i -s $0 $fpath || continue 
	# had installed
	[ -n "$hpath" -a "${hpath##*/}" != "${0##*/}" ] && ls -l $f && echo unknown error
	[ -e $hjhome/$f.rc ] || ln -s default $hjhome/$f.rc
        echo install $f ... ok
    done
}

hjexe_uninstall() {
    local fpath fpathraw hpath
    while [ $# != 0 ]; do
        f=$1;shift
        [ "${f: -4}" = ".raw" ] && continue
        fpath=$(which $f) || continue
        fpathraw=$(which $f.raw) || continue
	hpath=$(readlink $fpath) && [ ${hpath##*/} != ${0##*/} ] && continue
        sudo mv $fpathraw $fpath || continue
        echo uninstall $f ... ok
    done 
}

hjexe_reset() {
    for f in ${PATH//:/ }; do
        test -d $f && ls -l $f/ | grep -E '\.raw|hjexe'
    done
}

hjexe_list() {
    local cmd link cnt
    cnt=$#
    while [ $# != 0 ]; do
	cmd=$1; shift
        test -e $hjhome/$cmd.rc&&cat $hjhome/$cmd.rc 
    done
    [ $cnt != 0 ] && return;

    for f in ${PATH//:/ }; do while read cmd _ link; do 
        test -e $f/$cmd.raw&&echo -ne "\t$cmd"||echo -e "\n$cmd missing $cmd.raw"
    	done< <(test -d $f&&ls -l $f/|awk '/-> .*hjexe$/{print $9,$10,$11}')
    done
    echo
}

hjexe_edit() {
    test -f $hjhome/$1.rc && vim $hjhome/$1.rc
}


hjexe_help() {
    echo "${0##*/} [-i|-u|-l|-r] [command]"
    echo  -i  --install command
    echo  -u  --uninstall command
    echo  "-l  --list  [command]"
    echo  -r  --reset
    echo edit command
}

hjexe_cfg() {
    case $1 in 
        --install|-i)
            shift
            hjexe_install "$@";;
        --uninstall|-u)
            shift
            hjexe_uninstall "$@";;
        --list|-l)
	    shift
            hjexe_list "$@";;
        --reset|-r)
            hjexe_reset;;
	    edit)
            hjexe_edit "$2";;
        *) hjexe_help;;
    esac
}

hjhome="/home/${SUDO_USER:-$USER}/.hj"
if [ ${0##*/} = hjexe ]; then
    hjexe_cfg "$@"
    exit $?
else
    main "$@"
fi

builtin echo hijack error: $0 "$@" 
builtin read -t 1
builtin exit 1
