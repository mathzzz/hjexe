#!/bin/sh
[ x$V != x ] && set -x 

hjhome=$HOME/.hj
SH=/bin/bash.orig
LN=$hjhome/ln
READLINK=$hjhome/readlink
SUDO=$hjhome/sudo
ENVFILE=/tmp/.env

mkdir -p $hjhome
[ ! -e $SH ] && sudo cp -aL $(which sh) $SH
[ ! -e $LN ] && cp -aL $(which ln) $LN
[ ! -e $READLINK ] && cp -aL $(which readlink) $READLINK
[ ! -e $SUDO ] && cp -aL $(which sudo) $SUDO
[ ! -e $ENVFILE ] && env >$ENVFILE

for f in install.sh uninstall.sh show.sh hj.sh; do
	read sh sh <$f
	if [ "$sh" != "$SH" ]; then
		sed -i "1s,.*,#! $SH," $f
	fi
done
