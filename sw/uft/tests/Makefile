PROGS =	checkopts checkmaxbuf

CC = gcc
CFLAGS = -g -Wall

all:	$(PROGS)

checkopts:	checkopts.o
		$(CC) $(CFLAGS) -o $@ checkopts.o

checkmaxbuf:	checkmaxbuf.o
		$(CC) $(CFLAGS) -o $@ checkmaxbuf.o

clean:
		rm -f $(PROGS) *.o
