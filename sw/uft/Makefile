
SENDER = sender
RECEIVER = receiver

TARGET = $(SENDER) $(RECEIVER)

LIBS = -lm
CC = gcc
CFLAGS = -g -Wall

.PHONY: default all clean

default: $(TARGET)
all: default

OBJECTS = uft.o wrapper.o error.o

HEADERS = $(wildcard *.h)

RECEIVEROBJ = receiver.o
SENDEROBJ = sender.o

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $< -o $@

.PRECIOUS: $(TARGET) $(OBJECTS)

$(SENDER): $(OBJECTS) $(SENDEROBJ)
	$(CC) $(CFLAGS) $(SENDEROBJ) $(OBJECTS) $(LIBS) -o $@

$(RECEIVER) : $(RECEIVEROBJ) $(RECEIVEROBJ)
	$(CC) $(CFLAGS) $(RECEIVEROBJ) $(OBJECTS) -Wall $(LIBS) -o $@

clean:
	-rm -f *.o
	-rm -f $(TARGET)
