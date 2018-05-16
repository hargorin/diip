

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

#### UFT_REG_RX_BASE
Receiver base address. The receiver puts the received transaction to this start address. Every new filetransfer is written on the same address.

#### UFT_REG_TX_BASE
Transmitter base address. The data sent is read from this base address.

#### UFT_REG_RX_CTR
Counts the number of received transfers. (Not implemented)

#### UFT_REG_TX_SIZE
Number of bytes to send.

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