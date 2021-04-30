#!/bin/sh
[ x$V != x ] && set -x 
SH=/bin/bash.orig
[ ! -e $SH ] && sudo cp -aL $(which sh) $SH
./show.sh | grep hj && exit

hjhome=$HOME/.hj
LN=$hjhome/ln
READLINK=$hjhome/readlink
SUDO=$(which sudo).orig
[ ! -e $SUDO ] && sudo cp -aL $(which sudo) $SUDO
ENVFILE=/tmp/.env

mkdir -p $hjhome
[ ! -e $LN ] && cp -aL $(which ln) $LN
[ ! -e $READLINK ] && cp -aL $(which readlink) $READLINK
[ ! -e $ENVFILE ] && env >$ENVFILE
[ ! -e /bin/hjexe ] && $SUDO cp -fa $SH /bin/hjexe && $SUDO $SH -c 'cat hjexe.sh >/bin/hjexe'

for f in install.sh uninstall.sh show.sh hj.sh; do
	read sh sh <$f
	if [ "$sh" != "$SH" ]; then
		sed -i "1s,.*,#! $SH," $f
	fi
done

echo init ok
