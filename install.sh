#! /bin/sh
set -x
[ ! -f /bin/hjexe ] && { sudo cp -flv hjexe /bin/hjexe || exit; }
md5=$(md5sum.raw /bin/hjexe)

tgt=$(which $1)
tgt2=$tgt
tgt2=$(readlink.raw -f $tgt)
tgt_md5=$(md5sum.raw $tgt)
if [ "$md5" == "$tgt_md5" -a -f $tgt.raw -a "$(md5sum $tgt.raw)" != "$tgt_md5" ]; then
		ls -al $tgt2 $tgt.raw
		exit
fi

sudo cp.raw -fav $tgt2 $tgt.raw
sudo cp.raw -flv /bin/hjexe $tgt2
touch $HOME/.hj/$1.open
