


#Compiler and Linker
CC = g++
AR = ar

#Compiler flags and libraries
CFLAGS = -pg -pedantic -Wall -g -O0 -I../uft/ -std=c++11
LIBS = $(shell pkg-config opencv --libs)
LIBS += -L../uft/ -luft -lpthread 

#The Target Binary Program
TARGET      := diip_cc

#The Directories, Source, Includes, Objects, Binary and Resources
SRCDIR      := src
INCDIR      := inc
BUILDDIR    := obj
TARGETDIR   := bin
RESDIR      := res
SRCEXT      := cpp
DEPEXT      := d
OBJEXT      := o

#---------------------------------------------------------------------------------
#DO NOT EDIT BELOW THIS LINE
#---------------------------------------------------------------------------------
SOURCES     := $(shell find $(SRCDIR) -type f -name *.$(SRCEXT))
OBJECTS     := $(patsubst $(SRCDIR)/%,$(BUILDDIR)/%,$(SOURCES:.$(SRCEXT)=.$(OBJEXT)))

# Add include path
CFLAGS += -I$(INCDIR)/ $(`pkg-config opencv --cflags`)
CFLAGS += $(shell pkg-config opencv --cflags)

#Defauilt Make
all: ../uft/libuft.a resources $(TARGET)

../uft/libuft.a: ../uft/uft.o ../uft/error.o ../uft/util.o ../uft/wrapper.o ../uft/uft.h
	@rm ../uft/libuft.a 2>/dev/null || :
	@make -C ../uft/ lib

#Remake
remake: cleaner all

#Copy Resources from Resources Directory to Target Directory
resources: directories
	@cp $(RESDIR)/* $(TARGETDIR)/ 2>/dev/null || :

#Make the Directories
directories:
	@mkdir -p $(TARGETDIR)
	@mkdir -p $(BUILDDIR)

#Clean only Objecst
clean:
	@$(RM) -rf $(BUILDDIR)

#Full Clean, Objects and Binaries
cleaner: clean
	@$(RM) -rf $(TARGETDIR)
	@make -C ../uft/ clean

#Pull in dependency info for *existing* .o files
-include $(OBJECTS:.$(OBJEXT)=.$(DEPEXT))

#Link
$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $(TARGETDIR)/$(TARGET) $^ $(LIBS)

#Compile
$(BUILDDIR)/%.$(OBJEXT): $(SRCDIR)/%.$(SRCEXT)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<
	@$(CC) $(CFLAGS) $(INCDEP) -MM $(SRCDIR)/$*.$(SRCEXT) > $(BUILDDIR)/$*.$(DEPEXT)
	@cp -f $(BUILDDIR)/$*.$(DEPEXT) $(BUILDDIR)/$*.$(DEPEXT).tmp
	@sed -e 's|.*:|$(BUILDDIR)/$*.$(OBJEXT):|' < $(BUILDDIR)/$*.$(DEPEXT).tmp > $(BUILDDIR)/$*.$(DEPEXT)
	@sed -e 's/.*://' -e 's/\\$$//' < $(BUILDDIR)/$*.$(DEPEXT).tmp | fmt -1 | sed -e 's/^ *//' -e 's/$$/:/' >> $(BUILDDIR)/$*.$(DEPEXT)
	@rm -f $(BUILDDIR)/$*.$(DEPEXT).tmp

profile: 
	@rm callgrind.out.*
	valgrind --tool=callgrind ./bin/diip_cc res/room.jpg
	kcachegrind callgrind.out.*

#Non-File Targets
.PHONY: all remake clean cleaner resources profile
