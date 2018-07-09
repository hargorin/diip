# diip control center
======================

## Requirements
```bash
sudo apt install libopencv-dev
```

## Build
```bash
make
```

## Dev notes
To detect memory leaks:
```bash
valgrind ./bin/diip_cc res/mountain_medium.tif -s
```
Debugging:
```bash
gdb --args ./bin/diip_cc res/mountain_medium.tif -s
```