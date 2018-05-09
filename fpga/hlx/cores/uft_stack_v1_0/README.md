

## AXI lite
Usage of the axi_ctrl.vhd component

### Registers
`0` being the lesat significant bit

#### UFT_REG_STATUS
| Bit           | Name          | Description |
| ------------- | ------------- | ----------- |
| `0`   		| tx_ready      | Transmitter is ready to start a transmission |

#### UFT_REG_CONTROL
| Bit           | Name          | Description |
| ------------- | ------------- | ----------- |
| `0`   		| tx_start      | Start a UFT transmission. Only possible if tx_ready in UFT_REG_STATUS is `1` |

### Signals

| signal        | R/W | Usage           |
| ------------- | --- | ------------- |
| slv_reg0 		| RO  | UFT_REG_STATUS |
| slv_reg1 		| WO  | UFT_REG_CONTROL |
| slv_reg2 		| WO  | UFT_REG_RX_BASE |
| slv_reg3 		| WO  | UFT_REG_TX_BASE |
| slv_reg4 		| RO  | UFT_REG_RX_CTR |
| slv_reg5 		| WO  | UFT_REG_TX_SIZE |
| slv_reg6 		|     |  |
| slv_reg7 		|     |  |
| slv_reg8 		|     |  |
| slv_reg9 		|     |  |
| slv_reg10 	|     |  |
| slv_reg11 	|     |  |
| slv_reg12 	|     |  |
| slv_reg13 	|     |  |
| slv_reg14 	|     |  |
| slv_reg15 	|     |  |
| slv_reg_rden 	|     | '1' when valid read address with acceptance of read address by slave |
| slv_reg_wren 	|     | '1' when valid write address |
| reg_data_out 	|     | Register data passed to AXI bus |
| byte_index 	|     |  |
| aw_en 		|     |  |