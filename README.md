# hjexe
hijacke execute program

make

sudo make install gcc
sudo make install ld
sudo make install bash
sudo make install sh 

mkfifo /tmp/log.p


#term 1
cat /tmp/log.p | gzip -9 > /tmp/log.gz

#term 2
strace -f -s 100 -o /tmp/log.p 

#term 3
date >/tmp/log.p

