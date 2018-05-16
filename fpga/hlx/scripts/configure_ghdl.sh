#!/bin/bash

if [ ! -n "$1" ]
then
  echo "Usage: `basename $0` top_desing_unit"
  exit 85
fi 

mkdir -p build/ghdl
rm -f build/ghdl/*
cd build/ghdl/

TOP=$1

# Add all vhd sources
SOURCES="$(find ../../cores/ -name *.vhd)"
SOURCES="$SOURCES $(find ../../cores/ -name *.vhd)"

ghdl -a  --work=unisim --ieee=synopsys -fexplicit ../../unisim/unisim_VCOMP.vhd
ghdl -a  --work=unisim --ieee=synopsys -fexplicit ../../unisim/unisim_VPKG.vhd
# ghdl -a --work=unisim --ieee=synopsys -fexplicit src/unisim/unisim_VITAL.vhd
# ghdl -a --work=unisim --workdir=unisim --ieee=synopsys -fexplicit src/unisim/unisim_SMODEL.vhd

ghdl -i  --ieee=synopsys -fexplicit $SOURCES
ghdl -m  --ieee=synopsys -fexplicit $TOP
ghdl --gen-makefile --ieee=synopsys -fexplicit $TOP > Makefile


sed '8s/^/GHDLRUNFLAGS=--vcd='$TOP'.vcd --wave='$TOP'.ghw --ieee-asserts=disable-at-0 /' Makefile > Makefile_
mv Makefile_ Makefile
sed 's/^GHDLFLAGS=.*/GHDLFLAGS= --ieee=synopsys -fexplicit/g' Makefile > Makefile_
mv Makefile_ Makefile
