
TARGET = diipwallis

LIBS = -lm
CC = gcc
CFLAGS = -O3 -g -Wall
INCLUDES = -I../uft/

.PHONY: default all clean

default: $(TARGET)
all: default

OBJECTS = main.o ../uft/uft.o ../uft/wrapper.o ../uft/error.o ../uft/util.o

HEADERS = $(wildcard *.h) ../uft/*.h

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

.PRECIOUS: $(TARGET) $(OBJECTS)

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) $(INCLUDES) $(OBJECTS) $(LIBS) -o $@

clean:
	-rm -f *.o
	-rm -f $(TARGET)
