#!/bin/sh
test -n "$V" && set -x 

hjhome=/home/${SUDO_USER:-$USER}/.hj

for f in bash readlink; do 
    ocmd=$(which $f).orig
    if [ -f $ocmd && -x $ocmd ]; then
        :
    else 
        sudo ln ${ocmd%.*} $ocmd || exit "error: ln $ocmd" 
    fi
done

envfile=/tmp/.env

mkdir -p $hjhome
