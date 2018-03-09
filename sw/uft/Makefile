
SENDER = sender
RECEIVER = receiver

TARGET = $(SENDER) $(RECEIVER)

LIBS = -lm
CC = gcc
CFLAGS = -g -Wall

.PHONY: default all clean

default: $(TARGET)
all: default

# OBJECTS = $(patsubst %.c, %.o, $(wildcard *.c))
OBJECTS = sender.o uft.o

HEADERS = $(wildcard *.h)

RECEIVEROBJ = receiver.o uft.o

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $< -o $@

.PRECIOUS: $(TARGET) $(OBJECTS)

$(SENDER): $(OBJECTS)
	$(CC) $(OBJECTS) -Wall $(LIBS) -o $@

$(RECEIVER) : $(RECEIVEROBJ)
	$(CC) $(RECEIVEROBJ) -Wall $(LIBS) -o $@

clean:
	-rm -f *.o
	-rm -f $(TARGET)