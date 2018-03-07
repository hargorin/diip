# diip - Software

Contains software for testing.

| Project | Description |
| ------- | :----------- |
| image2file | Convert tiff to binary data for FPGA |
| file2image | Convert binary data from FPGA to tiff |
| uft | UDP file transfer stack |


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

