# hjexe
hijacke execute program

make

install gcc
install ld

mkfifo /tmp/log.p
# exec ${MYFD} <> /tmp/log.p
# cat /tmp/log.p


#term 1
cat /tmp/log.p | gzip -9 > /tmp/log.gz

#term 2
strace -f -s 100 -o /tmp/log.p 

#term 3
date >/tmp/log.p

