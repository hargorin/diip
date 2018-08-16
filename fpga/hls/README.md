# Vivado HLS projects

## Projects
```
 projects
│   ├── controller      # diip memory controller
│   ├── sobel           # Edge detecting Sobel IP-core
│   ├── stream_dummy    # dummy stream IP immitating Wallis filter
│   └── template        # template folder structure
│   └── wallis          # Wallis filter


.
├── clahe           # clahe implementation
├── controller      # wallis memory controller
├── sobel           # 3x3 sobel filter
├── stream_dummy    # stream dummy immitating wallis filter
├── template        # HLS template folder structure
├── wallis_256b     # Wallis filter with 256 bit AXI stream
└── wallis_8b       # Wallis filter with 8 bit AXI stream
```

## Install instructrions
```bash
sudo apt-get install libjpeg62
# Create link to libtiff5
sudo ln -s /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.3
```
## Build instructrions
Requires Vivado HLS and the settings file sourced.
```bash
make NAME=<project name>
```

## Make targets
```bash
make csim   # run c simulation only
make synth  # run synthesis
make cosim  # run vhdl co-simulation (requires synth)
make export # export project as IP-XACT (requires cosim)
```
