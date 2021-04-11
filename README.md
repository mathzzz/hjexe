# hjexe
hijacke execute program

make
sudo cp -a hjexe /bin/
./install gcc
./install ld

mkfifo /tmp/log.p
exec ${MYFD}"<>" /tmp/log.fifo
cat /tmp/log.fifo


#term 1
cat /tmp/log.fifo | gzip -9 > /tmp/log.gz

#term 2
#strace -f -s 100 -o /tmp/log.fifo
./hj.sh cmd par1 par2 ...

#term 3
date >/tmp/log.p

