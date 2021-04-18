
src := $(wildcard *.c)
obj := $(src:.c=.o)
tgt := hjexe


all:$(obj)
	gcc -g -o $(tgt) $^

.c.o:
	gcc -g3 -pg -c $< 

clean:
	rm -f *.o *.d *.a *.so hjexe
