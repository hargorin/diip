# diip - Software

Contains PC software for testing and benchmark.


## Folder Structure
```
.
├── clahe						# CLAHE filter PC program
├── diip_cc 					# diip Control Center for diip_faster hlx project (VHDL)
├── diip_cc_hls 				# diip Control Center for diip hlx project (HLS)
├── file2image 					# Converts image file to binary file containing pixels
├── image2file  				# Converts binary file to image (iverse of file2image)
├── matlab 						# Contains Matlab scripts for testing
├── uft 						# UDP file transfer stack library, used in diip_cc
├── wallis_filter 				# C++ implementation of Wallis filter
└── wallis_filter_datatxt_out 	# C++ implementation of Wallis filter with text output for VHDL tb
```

## Build instructions
```
sudo apt install libopencv-dev
make
```

## image2file
### Usage
```bash
cd image2file/
make
./image2file input_file output_file
```


## file2image
### Usage
```bash
cd file2image/
make
./file2image input_file output_file width height
```

## uft
### Usage
```bash
cd uft/
make
./sender IP filename
./receiver filename
```

