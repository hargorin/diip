# filesplit

Used to split a binary file into 21*IMG_WIDTH sized files for testing.

## Usage
```bash
./filesplit ../room_in.bin 128 out/
# Now run the tcl testbench
./filemerge ../room_out.bin out/in*.bin
# Now run the file2image from ../
```