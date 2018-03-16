PROGS =	checkopts

CC = gcc
CFLAGS = -g -Wall

all:	$(PROGS)

checkopts:	checkopts.o
		$(CC) $(CFLAGS) -o $@ checkopts.o

clean:
		rm -f $(PROGS) *.o
