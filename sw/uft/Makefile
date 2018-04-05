
SENDER = sender
RECEIVER = receiver
BENCHMARK = benchmark

TARGET = $(SENDER) $(RECEIVER) $(BENCHMARK)

LIBS = -lm
CC = gcc
CFLAGS = -O3 -g -Wall

.PHONY: default all clean

default: $(TARGET)
all: default

OBJECTS = uft.o wrapper.o error.o util.o

HEADERS = $(wildcard *.h)

RECEIVEROBJ = receiver.o
SENDEROBJ = sender.o
BENCHMARKOBJ = benchmark.o

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $< -o $@

.PRECIOUS: $(TARGET) $(OBJECTS)

$(SENDER): $(OBJECTS) $(SENDEROBJ)
	$(CC) $(CFLAGS) $(SENDEROBJ) $(OBJECTS) $(LIBS) -o $@

$(RECEIVER) : $(OBJECTS) $(RECEIVEROBJ)
	$(CC) $(CFLAGS) $(RECEIVEROBJ) $(OBJECTS) -Wall $(LIBS) -o $@

$(BENCHMARK) : $(OBJECTS) $(BENCHMARKOBJ)
	$(CC) $(CFLAGS) $(BENCHMARKOBJ) $(OBJECTS) -Wall $(LIBS) -o $@

clean:
	-rm -f *.o
	-rm -f $(TARGET)
