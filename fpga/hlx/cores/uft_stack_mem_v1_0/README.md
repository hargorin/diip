

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

#### UFT_REG_USER_n
These registers are set by the UFT USER command (command code 0x04, data 1 = offset, data 2 = data).

#### UFT_REG_TX_SIZE
Number of bytes to send.

### Signals

| signal        | R/W | Off [hex] | Usage           |
| ------------- | --- | --------- | ------------- |
| slv_reg0 		| RO  |        00 |UFT_REG_STATUS |
| slv_reg1 		| WO  |        04 |UFT_REG_CONTROL |
| slv_reg2 		| WO  |        08 |UFT_REG_RX_BASE |
| slv_reg3 		| WO  |        0C |UFT_REG_TX_BASE |
| slv_reg4 		| RO  |        10 |UFT_REG_RX_CTR |
| slv_reg5 		| WO  |        14 |UFT_REG_TX_SIZE |
| slv_reg6 		|     |        18 | |
| slv_reg7 		|     |        1C | |
| slv_reg8 		| RO  |        20 |UFT_REG_USER_0 |
| slv_reg9 		| RO  |        24 |UFT_REG_USER_1 |
| slv_reg10 	| RO  |        28 |UFT_REG_USER_2 |
| slv_reg11 	| RO  |        2C |UFT_REG_USER_3 |
| slv_reg12 	| RO  |        30 |UFT_REG_USER_4 |
| slv_reg13 	| RO  |        34 |UFT_REG_USER_5 |
| slv_reg14 	| RO  |        38 |UFT_REG_USER_6 |
| slv_reg15 	| RO  |        3C |UFT_REG_USER_7 |