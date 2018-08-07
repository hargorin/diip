# p6 Report

## Notes Noah
### Measurements to do
* [ ] Latency of receiving path (from PHY to UFT out stream)
* [x] ILA/Trace measurement showing slow output pixels solution A
* [x] ILA/Trace measurement showing fast output pixels solution B -> vhdlcontrollerout.png
* [ ] Maximum UFT transfer speed
* [ ] Build v1.0 on ime machine
* [x] Build v2.0 on ime machine

### Graphics to draw
* [x] Dataflow block diagram for solution A (with memory)
* [x] Dataflow block diagram for solution B (stream)
* [x] Graphic for memory layout solution A
* [x] dc top block design
* [x] simple FiFo overview
* [x] Graphic for memory layout solution B

### Code to correct
* [ ] Change all row_* pointers in dc_mmu to col* pointer which would make sense

### Backlog
* [ ] Report utilization VHDL <-> HLS

### Check with Jan
* [ ] Where do you describe why you need the pixels coloumn wise? ch:ip:concept?
* [ ] if-statements in HLS controller: What did we want to show?
* [ ] Reference to code files - how?
* [x] Theoretical background: AXI4-Stream?

### New Wallis parameter for IP validation
```C
com->writeUserReg(3, 0b00101101101101000000); // wa_par_c_gvar 2925
com->writeUserReg(4, 0b110100); // wa_par_c 0.8125
com->writeUserReg(5, 0b00001010100011000000); // wa_par_ci_gvar 675
com->writeUserReg(6, 0b00110111100100); // wa_par_b_gmean 55.5625
com->writeUserReg(7, 0b100100); // wa_par_bi 0.5625
```

### Validation
```bash
$ ./sender 192.168.5.9 42042 payload/cat.jpg
UFT Sender demo
destination 192.168.5.9:42042
HURRAY! All 1036 packets have been acknowledged.
time elapsed: 1.18s Speed: 0.859 MB/s Size: 1.012 MB
```

## Benchmark

Image source: https://www.hd-wallpapersdownload.com/script/new-wallpaper/desktop-hd-pics-of-black-and-white-animals.jpg

| Solution | Image | Throughput | Image File |
|----------|-------|------------|------------|
| HLS      | mountain | 0.168MB/s | mountain_fpga_hls.tif |
| HLS      | room     | 0.170MB/s | room_fpga_hls.tif |
| HLS      | cat480p  | 0.170MB/s |  |
| HLS      | cat720p  | diip_cc error |  |
| HLS      | cat1080p  | 0.168MB/s |  |
| HLS      | cat2160p  | 0.161MB/s |  |
| VHDL     | cat480p  | 0.89MB/s |  |
| VHDL     | cat720p  | 1.291MB/s |  |
| VHDL     | cat1080p  | 2.348MB/s |  |
| VHDL     | cat2160p  | 4.115MB/s |  |
