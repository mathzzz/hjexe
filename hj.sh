#! /bin/sh

# install, according to the .hj/xxx hook command

for f in `ls $HOME/.hj/*.open`; do 
	name=$(basename $f)
    ./install.sh ${name%.open}
done
env > /tmp/.env

"$@"

for f in `ls $HOME/.hj/*.open`; do 
	name=$(basename $f)
    ./uninstall.sh ${name%.open}
done


