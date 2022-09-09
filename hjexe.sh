#! /bin/bash.orig 
[ "$HJDEBUG" = 1 ] && set -ex

sudo() { 
    local sudo
    [ "$UID" != 0 ] && sudo=sudo
    type -P sudo >/dev/null || unset sudo
    command $sudo "$@"
}

execute() {
    local cnt=0 f=$0
    [ -x $f.raw ] && exec -a $0 $0.raw "$@"
    while link=$(readlink $f); do
        [ ${link:0:1} = / ] || link=${f%/*}/$link
        f=$link
        [ -x $f.raw ] && exec -a $f $f.raw "$@"
        [ $((cnt++)) = 8 ] && { echo not found "$f.raw" 2>&1; break; }
    done
    false
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

hjexe_backup() {
    local f raw;
    test -d $hjhome || mkdir -p $hjhome
    test -e $hjhome/default || { 
		echo 'echo cd $PWD\; $0 "$@" >> ${BASH_SOURCE%.rc}.log'
	} >$hjhome/default
    while [ $# != 0 ]; do
        f=$(type -P $1) || exit
        raw=$f.raw; [ -f $f.raw ] || raw=$f
        if [ ! -e $f.orig ]; then 
            sudo cp -alL $raw $f.orig || exit
        fi
        shift
    done
}

hjexe_install() {
    local f fpath hpath filehead default=1

    while [ $# != 0 ]; do 
        f=$1; shift
        [ "${f: -4}" = ".raw" ] && continue;
        fpath=$(type -P "$f")|| { echo "$f" does not exist in "$PATH"; continue; }
        read -n2 filehead < $fpath
        if [ "$filehead" = "#!" ]; then
            $fpath is script and ignored.
            continue
        fi
        if hpath=$(readlink $fpath); then # its symbolic file
            if [[ "${hpath: -4}" != ".raw" &&  "${hpath##*/}" != "${0##*/}" ]]; then
                sudo mv $fpath $fpath.raw
            fi
        else
            [ -e $fpath.raw ]|| sudo mv $fpath $fpath.raw
        fi
        sudo ln -is $0 $fpath 
        test ! -e $hjhome/$f.rc && cp $hjhome/default $hjhome/$f.rc 
    done
}

hjexe_uninstall() {
    local fpath fpathraw hpath
    while [ $# != 0 ]; do
        f=$1;shift
        [ "${f: -4}" = ".raw" ] && continue
        fpath=$(type -P $f) || continue
        fpathraw=$(type -P $f.raw) || continue
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

hjexe_do() {
    cd $hjhome/
    "$@" 
}


hjexe_help() {
    echo "${0##*/} [-i|-u|-l|-r] [command]"
    echo  -i  --install command
    echo  -u  --uninstall command
    echo  "-l  --list  [command]"
    echo  -r  --reset
    echo  command
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
        --backup)
            shift
            hjexe_backup "$@";;
        -h|--help) hjexe_help;;
        *)
            hjexe_do "$@";;
    esac
}

hjhome="/tmp/${SUDO_USER:-$USER}/.hj"
if [[ ${0##*/} = hjexe || ${0##*/} = hjexe.sh ]]; then
    hjexe_cfg "$@"
    exit $?
else
    main "$@"
fi

builtin echo hijack error: $0 "$@" 
builtin read -t 1
builtin exit 1
