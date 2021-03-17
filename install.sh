#! /bin/sh

tgt=$(which $1)
if [ -h $tgt ]; then
	ls -al $tgt
	echo do nothing.
	exit
fi

if [ -f $tgt.raw ]; then
	echo $tgt exist.
	exit
fi

sudo cp -av $tgt $tgt.raw
sudo cp -flv /bin/hjexe $tgt
touch $HOME/.hj/$1.open
