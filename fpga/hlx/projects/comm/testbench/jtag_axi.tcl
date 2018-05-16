reset_hw_axi [get_hw_axis hw_axi_1]
set address 0x08000000
set gpio 0x40000000
set rt axi1_bram_rt
set wt axi1_bram_wr

create_hw_axi_txn wt [get_hw_axis hw_axi_1] -address 08000000 -data {11111111_22222222_33333333_44444444_55555555_66666666_77777777_88888888} -len 8 -type write
create_hw_axi_txn rt [get_hw_axis hw_axi_1] -address 08000000 -len 8 -type read


create_hw_axi_txn sz512 [get_hw_axis hw_axi_1] -address $gpio -data {0000_0200} -len 8 -type write
create_hw_axi_txn sz513 [get_hw_axis hw_axi_1] -address $gpio -data {0000_0201} -len 8 -type write
create_hw_axi_txn sz1k [get_hw_axis hw_axi_1] -address $gpio -data {0000_0400} -len 8 -type write
create_hw_axi_txn sz1k1 [get_hw_axis hw_axi_1] -address $gpio -data {0000_0401} -len 8 -type write
create_hw_axi_txn sz2k [get_hw_axis hw_axi_1] -address $gpio -data {0000_0800} -len 8 -type write
create_hw_axi_txn sz4k [get_hw_axis hw_axi_1] -address $gpio -data {0000_1000} -len 8 -type write
create_hw_axi_txn sz8k [get_hw_axis hw_axi_1] -address $gpio -data {0000_2000} -len 8 -type write
create_hw_axi_txn sz16k [get_hw_axis hw_axi_1] -address $gpio -data {0000_4000} -len 8 -type write
create_hw_axi_txn sz32k [get_hw_axis hw_axi_1] -address $gpio -data {0000_8000} -len 8 -type write
create_hw_axi_txn sz64k [get_hw_axis hw_axi_1] -address $gpio -data {0001_0000} -len 8 -type write
create_hw_axi_txn sz128k [get_hw_axis hw_axi_1] -address $gpio -data {0002_0000} -len 8 -type write
create_hw_axi_txn sz256k [get_hw_axis hw_axi_1] -address $gpio -data {0004_0000} -len 8 -type write
create_hw_axi_txn sz512k [get_hw_axis hw_axi_1] -address $gpio -data {0008_0000} -len 8 -type write
create_hw_axi_txn sz1M [get_hw_axis hw_axi_1] -address $gpio -data {0010_0000} -len 8 -type write
create_hw_axi_txn sz2M [get_hw_axis hw_axi_1] -address $gpio -data {0020_0000} -len 8 -type write
create_hw_axi_txn sz4M [get_hw_axis hw_axi_1] -address $gpio -data {0040_0000} -len 8 -type write
create_hw_axi_txn sz8M [get_hw_axis hw_axi_1] -address $gpio -data {0080_0000} -len 8 -type write


run_hw_axi sz1k
run_hw_axi rt
