# Vivado HLx project

## Folder structure
```
.
├── build                           # Output files
│   └── cores                       # Generated cores
├── config                          # Board configuration
├── cores                           # IP core definitions
│   ├── axi_master_burst_v2_0
│   ├── debounce_v1_0
│   ├── impulse_generator_v1_0
│   ├── temac_support_v1_0
│   ├── udp_ip_stack_v1_0
│   └── uft_stack_v1_0
├── projects                        # Projects
│   ├── diip                        # diip full project
│   ├── comm                        # diip communication project
│   └── sobel                       # diip sobel filter project
├── scripts                         # Used for build process
├── simulation                      # Simulation ressources
├── src
│   └── constraints                 # Global constraints
└── unisim                          # Simulation sources
```

## Build Process
The project to be built is defined in the Makefile variable ```NAME```.

### Build all
```bash
make
```

### Partial Builds
```bash
make cores      # Build IP cores only
make project    # Build Project only
make impl       # Run Synthesis and Implementation only, good for hosts
                #   without the necessary licenses installed
make bit        # Run Synthesis, Implementation and generate bitstream
make flash      # Configure FPGA
```

## Project Sobel
Sobel image core from ```../hls/sobel``` running on the FPGA with JTAG to AXI interface to send and receive data.

### Build
```bash
make NAME=sobel all
make NAME=sobel flash
```

### Run
Run the tcl script ```projects/sobel/testbench/sobel_tb.tcl``` with the arguments

| Argument | Description |
| -------- | :---------- |
| infile | Input binary file converted using ```image2file``` |
| outfile | Output binary file. Use ```file2image``` to convert to image |
| width | Image width |
| height | Image height |
| burst_length | JTAG AXI data length = width/4 |

#### Example
```bash
../../sw/image2file/image2file ../../sw/image2file/input_files/bridge.tiff build/bridge.bin
vivado -mode batch -source projects/sobel/testbench/sobel_tb.tcl \
    -tclargs build/bridge.bin build/bridge_fpga.bin 512 512 128
../../sw/file2image/file2image build/bridge_fpga.bin build/bridge_fpga.tiff 510 510 -s
```

## Project diip
Communication project containing the full UFT stack. Files can be sent to the FPGA from a computer and sent back. 

### Build
```bash
make NAME=diip all
make NAME=diip flash
```

### Run
Set up a network with static IP for the computer.

| Property | Computer | FPGA |
| -------- | :----------: | :----------: |
| IP address | 192.168.5.10 | 192.168.5.9 |
| Hardware address | | 00:23:20:21:22:23 |
| UFT send port | 42042 | 2222 |
| UFT receive port | 2222 | 42042 |

Use the ```sender``` and ```receiver``` programs to send and receive data. To start a transmission on the FPGA push the SW4 button. To set transmission settings run
```bash
vivado -mode tcl build/projects/diip.xpr
source projects/diip/testbench/jtag_axi.tcl
```

See ```projects/diip/testbench/jtag_axi.tcl``` for available transmission sizes (```run_hw_axi sz1k```, ```run_hw_axi sz2k```,..)

For a file transfer test run
```bash
cd ../../sw/uft
./sender 192.168.50.9 testfile.txt
./receiver hifpga.bin
# Push SW4
```

## Simulation
The Simulation requires ghdl.
```bash
# ghdl Version v0.33
sudo apt install libgnat-4.9
wget https://github.com/ghdl/ghdl/releases/download/v0.33/ghdl_0.33-1jessie1_amd64.deb
sudo dpkg -i ghdl_0.33-1jessie1_amd64.deb
rm ghdl_0.33-1jessie1_amd64.deb
```

Run simulation with the make commant sim and variable ```TOP``` that holds the name of the entity to be simulated. For example
```bash
make TOP=uft_top_tb sim
```

All testbenches can be fount using
```bash
find cores -name *tb.vhd
# cores/axi_master_burst_v2_0/bench/axi_master_burst_model_tb.vhd
# cores/debounce_v1_0/bench/debounce_tb.vhd
# cores/impulse_generator_v1_0/bench/impulse_generator_tb.vhd
# cores/temac_support_v1_0/bench/demo_tb.vhd
# cores/udp_ip_stack_v1_0/bench/arp_STORE_tb.vhd
# cores/udp_ip_stack_v1_0/bench/arp_tb.vhd
# cores/udp_ip_stack_v1_0/bench/arpv2_tb.vhd
# cores/udp_ip_stack_v1_0/bench/IP_av2_complete_nomac_tb.vhd
# cores/udp_ip_stack_v1_0/bench/IP_complete_nomac_tb.vhd
# cores/udp_ip_stack_v1_0/bench/IPv4_RX_tb.vhd
# cores/udp_ip_stack_v1_0/bench/IPv4_TX_tb.vhd
# cores/udp_ip_stack_v1_0/bench/UDP_av2_complete_nomac_tb.vhd
# cores/udp_ip_stack_v1_0/bench/UDP_complete_nomac_tb.vhd
# cores/udp_ip_stack_v1_0/bench/UDP_RX_tb.vhd
# cores/udp_ip_stack_v1_0/bench/UDP_TX_tb.vhd
# cores/uft_stack_v1_0/bench/fifo_32i_8o_tb.vhd
# cores/uft_stack_v1_0/bench/fifo_8i_32o_tb.vhd
# cores/uft_stack_v1_0/bench/uft_top_tb.vhd
# cores/uft_stack_v1_0/bench/uft_tx_cmd_assembler_tb.vhd
# cores/uft_stack_v1_0/bench/uft_tx_control_tb.vhd
# cores/uft_stack_v1_0/bench/uft_tx_data_assembler_tb.vhd
# cores/uft_stack_v1_0/bench/uft_tx_tb.vhd
```

The results are located in ```build/ghdl```. Open the file ```build/ghdl/*.ghw``` or ```*.vcd``` with you favourite wave viewer (gtkwave for example)
```bash
sudo apt install gtkwave
gtkwave
```

Clean simulation results using
```bash
make clean-sim
```

### ghdl v0.34
```bash
# ghdl Version v0.34 UNTESTED!
sudo apt install libgnat-4.9
cd /tmp
mkdir ghdl
cd ghdl
wget https://github.com/tgingold/ghdl/releases/download/v0.34/ghdl-v0.34-mcode-ubuntu.tgz
tar -xvzf ghdl-v0.34-mcode-ubuntu.tgz
sudo cp -rv bin/* /usr/local/bin/
sudo cp -rv lib/* /usr/local/lib/
sudo cp -rv include/* /usr/local/include/
```



