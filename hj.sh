#! /home/zjw/.hj/sh

# install, according to the .hj/xxx hook command
scriptdir=$(dirname $0)
for f in `ls $HOME/.hj/*.open`; do 
	name=$(basename $f)
    $scriptdir/install.sh ${name%.open}
done

echo begin .................
time "$@"
echo end.................

for f in `ls $HOME/.hj/*.open`; do 
	name=$(basename $f)
    $scriptdir/uninstall.sh ${name%.open}
done


