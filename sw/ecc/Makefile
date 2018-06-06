CC = g++
RM = rm -rf

CFLAGS = -Wall -O3

SRCS = main.cpp
PROG = mean_var

OPENCV = `pkg-config opencv --cflags --libs`
LIBS = $(OPENCV)

all: $(PROG)

$(PROG):$(SRCS)
	$(CC) $(CFLAGS) -o $(PROG) $(SRCS) $(LIBS)

clean:
	$(RM) $(PROG)
