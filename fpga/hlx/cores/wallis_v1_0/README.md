## Simulate Wallis Top

### Example
```bash
./../../../../sw/wallis_filter_datatxt_out/wallis_filter ../../../../sw/wallis_filter_datatxt_out/input_files/room32x32.tif build/w_room.tif > bench/in_pixel.txt
```
Change IMG_WIDTH and IMG_HEIGHT in file wallis>top_tb.vhd
	-- IMG_WIDTH and IMG_HEIGTH must be the same as the input image

```bash
make --directory ../../ TOP=wallis_top_tb sim
cat ../../build/ghdl/axi_stream_res_00* | tr -d ' \n'  | xxd -r -p > bench/out_pixel.bin
../../../../sw/file2image/file2image bench/out_pixel.bin bench/out.tif 12 12
```
