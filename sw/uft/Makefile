
SENDER = sender
RECEIVER = receiver
BENCHMARK = benchmark
COMMAND = command
LIB = libuft.a

TARGET = $(SENDER) $(RECEIVER) $(BENCHMARK) $(COMMAND)

LIBS = -lm
CC = gcc
CFLAGS = -O3 -g -Wall
AR = ar

.PHONY: default all clean

default: $(TARGET) $(LIB)
all: default

OBJECTS = uft.o wrapper.o error.o util.o

HEADERS = $(wildcard *.h)

RECEIVEROBJ = receiver.o
SENDEROBJ = sender.o
BENCHMARKOBJ = benchmark.o
COMMANDOBJ = command.o

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $< -o $@

.PRECIOUS: $(TARGET) $(OBJECTS)

$(SENDER): $(OBJECTS) $(SENDEROBJ)
	$(CC) $(CFLAGS) $(SENDEROBJ) $(OBJECTS) $(LIBS) -o $@

$(RECEIVER) : $(OBJECTS) $(RECEIVEROBJ)
	$(CC) $(CFLAGS) $(RECEIVEROBJ) $(OBJECTS) -Wall $(LIBS) -o $@

$(BENCHMARK) : $(OBJECTS) $(BENCHMARKOBJ)
	$(CC) $(CFLAGS) $(BENCHMARKOBJ) $(OBJECTS) -Wall $(LIBS) -o $@

$(COMMAND) : $(OBJECTS) $(COMMANDOBJ)
	$(CC) $(CFLAGS) $(COMMANDOBJ) $(OBJECTS) -Wall $(LIBS) -o $@

lib : $(LIB)
$(LIB) : uft.o uft.h
	$(AR) -cvq $(LIB) uft.o wrapper.o error.o util.o

clean:
	-rm -f *.o
	-rm -f $(TARGET)
