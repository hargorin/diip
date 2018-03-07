# Vivado HLS projects

## Projects
```
.
└── sobel   # Edge detecting Sobel IP-core
```

## Build instructrions
Requires Vivado HLS and the settings file sourced.
```bash
sudo apt-get install libjpeg62
# Create link to libtiff5
sudo ln -s /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.3
cd sobel/
make
```
