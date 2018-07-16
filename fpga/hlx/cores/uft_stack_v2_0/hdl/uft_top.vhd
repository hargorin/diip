-------------------------------------------------------------------------------
-- Title       : UFT Top Module
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_top.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Nov 22 15:53:25 2017
-- Last update : Mon Jul 16 11:19:18 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: UDP File Transfer top module, combines transmitter and receiver
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------


library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

use work.uft_pkg.all;

entity uft_top is
    generic (
        -- only treat packages arriving at INCOMMING_PORT as UFT packages
        INCOMMING_PORT : natural := 42042;
        -- Parameters for ip interface to Axi master burst
        FIFO_DEPTH : positive := 366; -- (1464/4)
        
        -- AXI Master burst Configuration
        C_M_AXI_ADDR_WIDTH  : integer range 32 to 64  := 32;
        C_M_AXI_DATA_WIDTH  : integer range 32 to 256 := 32;
        C_MAX_BURST_LEN     : Integer range 16 to 256 := 16;
        C_ADDR_PIPE_DEPTH   : Integer range 1 to 14   := 1;
        C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
        C_LENGTH_WIDTH      : INTEGER range 12 to 20  := 12;
        C_FAMILY            : string                  := "artix7";

        -- Parameters of Axi Slave Bus Interface S_AXI_CTRL
        C_S_AXI_DATA_WIDTH  : integer   := 32;
        C_S_AXI_ADDR_WIDTH  : integer   := 6
    );
    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- Controll
        -- ---------------------------------------------------------------------
        our_ip_address      : out STD_LOGIC_VECTOR (31 downto 0);
        our_mac_address         : out std_logic_vector (47 downto 0);

        tx_ready        : out  std_logic;

        -- RX user interface
        -- ---------------------------------------------------------------------
        M_AXIS_TVALID   : out   std_logic;
        M_AXIS_TDATA    : out   std_logic_vector(7 downto 0);
        M_AXIS_TLAST    : out   std_logic;
        M_AXIS_TREADY   : in    std_logic;

        rx_done        : out  std_logic; 
        rx_row_num         : out std_logic_vector(31 downto 0);
        rx_row_num_valid   : out std_logic;
        rx_row_size        : out std_logic_vector(31 downto 0);
        rx_row_size_valid  : out std_logic;

        -- User registers
        user_reg0           : out  std_logic_vector(31 downto 0);
        user_reg1           : out  std_logic_vector(31 downto 0);
        user_reg2           : out  std_logic_vector(31 downto 0);
        user_reg3           : out  std_logic_vector(31 downto 0);
        user_reg4           : out  std_logic_vector(31 downto 0);
        user_reg5           : out  std_logic_vector(31 downto 0);
        user_reg6           : out  std_logic_vector(31 downto 0);
        user_reg7           : out  std_logic_vector(31 downto 0);

        -- To UDP Receiver
        -- ---------------------------------------------------------------------
        -- Control
        udp_rx_start                : in std_logic;
        -- Header
        udp_rx_hdr_is_valid         : in std_logic;
        udp_rx_hdr_src_ip_addr      : in std_logic_vector (31 downto 0);
        udp_rx_hdr_src_port         : in std_logic_vector (15 downto 0);
        udp_rx_hdr_dst_port         : in std_logic_vector (15 downto 0);
        udp_rx_hdr_data_length      : in std_logic_vector (15 downto 0);
        -- Data
        udp_rx_tdata                : in std_logic_vector (7 downto 0);
        udp_rx_tvalid               : in std_logic;
        udp_rx_tlast                : in std_logic;

        -- To UDP Transmitter
        -- ---------------------------------------------------------------------
        -- Control
        udp_tx_start                : out std_logic;
        udp_tx_result               : in std_logic_vector (1 downto 0);
        -- Header
        udp_tx_hdr_dst_ip_addr      : out std_logic_vector (31 downto 0);
        udp_tx_hdr_dst_port         : out std_logic_vector (15 downto 0);
        udp_tx_hdr_src_port         : out std_logic_vector (15 downto 0);
        udp_tx_hdr_data_length      : out std_logic_vector (15 downto 0);
        udp_tx_hdr_checksum         : out std_logic_vector (15 downto 0);
        -- Data
        udp_tx_tvalid               : out std_logic;
        udp_tx_tlast                : out std_logic;
        udp_tx_tdata                : out std_logic_vector (7 downto 0);
        udp_tx_tready               : in  std_logic;


        -- TX Memory IP Interface
        -- ---------------------------------------------------------------------
        tx_ip2bus_mstrd_req       : out std_logic;
        tx_ip2bus_mstwr_req       : out std_logic;
        tx_ip2bus_mst_addr        : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
        tx_ip2bus_mst_length      : out std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
        tx_ip2bus_mst_be          : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
        tx_ip2bus_mst_type        : out std_logic;
        tx_ip2bus_mst_lock        : out std_logic;
        tx_ip2bus_mst_reset       : out std_logic;
        tx_bus2ip_mst_cmdack      : in  std_logic;
        tx_bus2ip_mst_cmplt       : in  std_logic;
        tx_bus2ip_mst_error       : in  std_logic;
        tx_bus2ip_mst_rearbitrate : in  std_logic;
        tx_bus2ip_mst_cmd_timeout : in  std_logic;
        tx_bus2ip_mstrd_d         : in  std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 );
        tx_bus2ip_mstrd_rem       : in  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
        tx_bus2ip_mstrd_sof_n     : in  std_logic;
        tx_bus2ip_mstrd_eof_n     : in  std_logic;
        tx_bus2ip_mstrd_src_rdy_n : in  std_logic;
        tx_bus2ip_mstrd_src_dsc_n : in  std_logic;
        tx_ip2bus_mstrd_dst_rdy_n : out std_logic;
        tx_ip2bus_mstrd_dst_dsc_n : out std_logic;
        tx_ip2bus_mstwr_d         : out std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
        tx_ip2bus_mstwr_rem       : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
        tx_ip2bus_mstwr_sof_n     : out std_logic;
        tx_ip2bus_mstwr_eof_n     : out std_logic;
        tx_ip2bus_mstwr_src_rdy_n : out std_logic;
        tx_ip2bus_mstwr_src_dsc_n : out std_logic;
        tx_bus2ip_mstwr_dst_rdy_n : in  std_logic;
        tx_bus2ip_mstwr_dst_dsc_n : in  std_logic;

        -- AXI lite interface for control
        -- ---------------------------------------------------------------------
        s_axi_ctrl_aclk     : in std_logic;
        s_axi_ctrl_aresetn  : in std_logic;
        s_axi_ctrl_awaddr   : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        s_axi_ctrl_awprot   : in std_logic_vector(2 downto 0);
        s_axi_ctrl_awvalid  : in std_logic;
        s_axi_ctrl_awready  : out std_logic;
        s_axi_ctrl_wdata    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_ctrl_wstrb    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        s_axi_ctrl_wvalid   : in std_logic;
        s_axi_ctrl_wready   : out std_logic;
        s_axi_ctrl_bresp    : out std_logic_vector(1 downto 0);
        s_axi_ctrl_bvalid   : out std_logic;
        s_axi_ctrl_bready   : in std_logic;
        s_axi_ctrl_araddr   : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        s_axi_ctrl_arprot   : in std_logic_vector(2 downto 0);
        s_axi_ctrl_arvalid  : in std_logic;
        s_axi_ctrl_arready  : out std_logic;
        s_axi_ctrl_rdata    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_ctrl_rresp    : out std_logic_vector(1 downto 0);
        s_axi_ctrl_rvalid   : out std_logic;
        s_axi_ctrl_rready   : in std_logic

    );
end entity uft_top;

architecture structural of uft_top is
    ----------------------------------------------------------------------------
    -- rx component declaration
    -- -------------------------------------------------------------------------
    component uft_rx is
        generic (
            INCOMMING_PORT : natural  := 42042;
            FIFO_DEPTH     : positive := 366
        );
        port (
            clk                    : in  std_logic;
            rst_n                  : in  std_logic;
            udp_rx_start           : in  std_logic;
            udp_rx_hdr_is_valid    : in  std_logic;
            udp_rx_hdr_src_ip_addr : in  std_logic_vector (31 downto 0);
            udp_rx_hdr_src_port    : in  std_logic_vector (15 downto 0);
            udp_rx_hdr_dst_port    : in  std_logic_vector (15 downto 0);
            udp_rx_hdr_data_length : in  std_logic_vector (15 downto 0);
            udp_rx_tdata           : in  std_logic_vector (7 downto 0);
            udp_rx_tvalid          : in  std_logic;
            udp_rx_tlast           : in  std_logic;
            M_AXIS_TVALID          : out std_logic;
            M_AXIS_TDATA           : out std_logic_vector(7 downto 0);
            M_AXIS_TLAST           : out std_logic;
            M_AXIS_TREADY          : in  std_logic;
            rx_done                : out std_logic;
            rx_row_num             : out std_logic_vector(31 downto 0);
            rx_row_num_valid       : out std_logic;
            rx_row_size            : out std_logic_vector(31 downto 0);
            rx_row_size_valid      : out std_logic;
            user_reg0              : out std_logic_vector(31 downto 0);
            user_reg1              : out std_logic_vector(31 downto 0);
            user_reg2              : out std_logic_vector(31 downto 0);
            user_reg3              : out std_logic_vector(31 downto 0);
            user_reg4              : out std_logic_vector(31 downto 0);
            user_reg5              : out std_logic_vector(31 downto 0);
            user_reg6              : out std_logic_vector(31 downto 0);
            user_reg7              : out std_logic_vector(31 downto 0);
            ack_cmd_nseq           : out std_logic;
            ack_cmd_ft             : out std_logic;
            ack_cmd_nseq_done      : in  std_logic;
            ack_cmd_ft_done        : in  std_logic;
            ack_seqnbr             : out std_logic_vector (23 downto 0);
            ack_tcid               : out std_logic_vector ( 6 downto 0);
            ack_dst_port           : out std_logic_vector (15 downto 0);
            ack_dst_ip             : out std_logic_vector (31 downto 0)
        );
    end component uft_rx;    

    ----------------------------------------------------------------------------
    -- UFT tx
    -- -------------------------------------------------------------------------
    component uft_tx is
        generic (
            C_M_AXI_ADDR_WIDTH  : integer range 32 to 64  := 32;
            C_M_AXI_DATA_WIDTH  : integer range 32 to 256 := 32;
            C_MAX_BURST_LEN     : Integer range 16 to 256 := 16;
            C_ADDR_PIPE_DEPTH   : Integer range 1 to 14   := 1;
            C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
            C_LENGTH_WIDTH      : INTEGER range 12 to 20  := 12;
            C_FAMILY            : string                  := "artix7"
        );
        port (
            clk                    : in  std_logic;
            rst_n                  : in  std_logic;
            data_size              : in  std_logic_vector(31 downto 0);
            data_src_addr          : in  std_logic_vector (C_M_AXI_ADDR_WIDTH-1 downto 0);
            tx_ready               : out std_logic;
            tx_start               : in  std_logic;
            dst_ip_addr            : in  std_logic_vector (31 downto 0);
            dst_port               : in  std_logic_vector (15 downto 0);
            ack_cmd_nseq           : in  std_logic;
            ack_cmd_ft             : in  std_logic;
            ack_cmd_nseq_done      : out std_logic;
            ack_cmd_ft_done        : out std_logic;
            ack_seqnbr             : in  std_logic_vector (23 downto 0);
            ack_tcid               : in  std_logic_vector ( 6 downto 0);
            ack_dst_port           : in  std_logic_vector (15 downto 0);
            ack_dst_ip             : in  std_logic_vector (31 downto 0);
            udp_tx_start           : out std_logic;
            udp_tx_result          : in  std_logic_vector (1 downto 0);
            udp_tx_hdr_dst_ip_addr : out std_logic_vector (31 downto 0);
            udp_tx_hdr_dst_port    : out std_logic_vector (15 downto 0);
            udp_tx_hdr_src_port    : out std_logic_vector (15 downto 0);
            udp_tx_hdr_data_length : out std_logic_vector (15 downto 0);
            udp_tx_hdr_checksum    : out std_logic_vector (15 downto 0);
            udp_tx_tvalid          : out std_logic;
            udp_tx_tlast           : out std_logic;
            udp_tx_tdata           : out std_logic_vector (7 downto 0);
            udp_tx_tready          : in  std_logic;
            ip2bus_mstrd_req       : out std_logic;
            ip2bus_mstwr_req       : out std_logic;
            ip2bus_mst_addr        : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
            ip2bus_mst_length      : out std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
            ip2bus_mst_be          : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
            ip2bus_mst_type        : out std_logic;
            ip2bus_mst_lock        : out std_logic;
            ip2bus_mst_reset       : out std_logic;
            bus2ip_mst_cmdack      : in  std_logic;
            bus2ip_mst_cmplt       : in  std_logic;
            bus2ip_mst_error       : in  std_logic;
            bus2ip_mst_rearbitrate : in  std_logic;
            bus2ip_mst_cmd_timeout : in  std_logic;
            bus2ip_mstrd_d         : in  std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 );
            bus2ip_mstrd_rem       : in  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
            bus2ip_mstrd_sof_n     : in  std_logic;
            bus2ip_mstrd_eof_n     : in  std_logic;
            bus2ip_mstrd_src_rdy_n : in  std_logic;
            bus2ip_mstrd_src_dsc_n : in  std_logic;
            ip2bus_mstrd_dst_rdy_n : out std_logic;
            ip2bus_mstrd_dst_dsc_n : out std_logic;
            ip2bus_mstwr_d         : out std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
            ip2bus_mstwr_rem       : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
            ip2bus_mstwr_sof_n     : out std_logic;
            ip2bus_mstwr_eof_n     : out std_logic;
            ip2bus_mstwr_src_rdy_n : out std_logic;
            ip2bus_mstwr_src_dsc_n : out std_logic;
            bus2ip_mstwr_dst_rdy_n : in  std_logic;
            bus2ip_mstwr_dst_dsc_n : in  std_logic
        );
    end component uft_tx;   

    ----------------------------------------------------------------------------
    -- AXI Lite controller
    -- -------------------------------------------------------------------------
    component axi_ctrl is
        generic (
            C_S_AXI_DATA_WIDTH : integer := 32;
            C_S_AXI_ADDR_WIDTH : integer := 6
        );
        port (
            tx_data_size            : out std_logic_vector(31 downto 0);
            tx_data_src_addr        : out std_logic_vector(31 downto 0);
            tx_ready                : in  std_logic;
            tx_start                : out std_logic;
            rx_data_dst_addr        : out std_logic_vector(31 downto 0);
            rx_data_transaction_ctr : in  std_logic_vector(31 downto 0);
            user_reg0               : in std_logic_vector(31 downto 0);
            user_reg1               : in std_logic_vector(31 downto 0);
            user_reg2               : in std_logic_vector(31 downto 0);
            user_reg3               : in std_logic_vector(31 downto 0);
            user_reg4               : in std_logic_vector(31 downto 0);
            user_reg5               : in std_logic_vector(31 downto 0);
            user_reg6               : in std_logic_vector(31 downto 0);
            user_reg7               : in std_logic_vector(31 downto 0);
            S_AXI_ACLK              : in  std_logic;
            S_AXI_ARESETN           : in  std_logic;
            S_AXI_AWADDR            : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_AWPROT            : in  std_logic_vector(2 downto 0);
            S_AXI_AWVALID           : in  std_logic;
            S_AXI_AWREADY           : out std_logic;
            S_AXI_WDATA             : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_WSTRB             : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
            S_AXI_WVALID            : in  std_logic;
            S_AXI_WREADY            : out std_logic;
            S_AXI_BRESP             : out std_logic_vector(1 downto 0);
            S_AXI_BVALID            : out std_logic;
            S_AXI_BREADY            : in  std_logic;
            S_AXI_ARADDR            : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_ARPROT            : in  std_logic_vector(2 downto 0);
            S_AXI_ARVALID           : in  std_logic;
            S_AXI_ARREADY           : out std_logic;
            S_AXI_RDATA             : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_RRESP             : out std_logic_vector(1 downto 0);
            S_AXI_RVALID            : out std_logic;
            S_AXI_RREADY            : in  std_logic
        );
    end component axi_ctrl;

    signal is_command             : std_logic;
    signal command_code           : std_logic_vector(6 downto 0);
    signal command_data1          : std_logic_vector(23 downto 0);
    signal command_data2          : std_logic_vector(31 downto 0);
    signal command_data_valid     : std_logic;
    signal is_data                : std_logic;
    signal data_tcid              : std_logic_vector( 6 downto 0);
    signal data_seq               : std_logic_vector(23 downto 0);
    signal data_meta_valid        : std_logic;
    signal data_tvalid            : std_logic;
    signal data_tlast             : std_logic;
    signal data_tdata             : std_logic_vector( 7 downto 0); 

    -- Tx
    signal data_src_addr   : std_logic_vector (C_M_AXI_ADDR_WIDTH-1 downto 0);
    signal tx_dst_ip_addr      : std_logic_vector (31 downto 0);
    signal tx_dst_port         : std_logic_vector (15 downto 0);

    -- Rx
    signal rx_src_port         : std_logic_vector (15 downto 0);  
    signal rx_src_ip           : std_logic_vector (31 downto 0);

    -- ack
    signal ack_cmd_nseq    : std_logic; -- acknowledge a sequence
    signal ack_cmd_ft      : std_logic; -- acknowledge a file transfer
    signal ack_cmd_nseq_done    : std_logic;
    signal ack_cmd_ft_done      : std_logic;
    -- data for commands
    signal ack_seqnbr              : std_logic_vector (23 downto 0);
    signal ack_tcid                : std_logic_vector ( 6 downto 0);
    signal ack_dst_port            : std_logic_vector (15 downto 0);
    signal ack_dst_ip              : std_logic_vector (31 downto 0);

    -- Connecting AXI ctrl
    signal tx_data_size       : std_logic_vector(31 downto 0);
    signal tx_ready_int : std_logic;
    signal tx_start : std_logic;
    signal rx_data_dst_addr : std_logic_vector(31 downto 0);
    signal rx_data_transaction_ctr : std_logic_vector(31 downto 0);

    -- User registers connecting rx_mem_ctrl and axi_ctrl
    signal user_reg0_i : std_logic_vector(31 downto 0);
    signal user_reg1_i : std_logic_vector(31 downto 0);
    signal user_reg2_i : std_logic_vector(31 downto 0);
    signal user_reg3_i : std_logic_vector(31 downto 0);
    signal user_reg4_i : std_logic_vector(31 downto 0);
    signal user_reg5_i : std_logic_vector(31 downto 0);
    signal user_reg6_i : std_logic_vector(31 downto 0);
    signal user_reg7_i : std_logic_vector(31 downto 0);

begin
        
    user_reg0 <= user_reg0_i;
    user_reg1 <= user_reg1_i;
    user_reg2 <= user_reg2_i;
    user_reg3 <= user_reg3_i;
    user_reg4 <= user_reg4_i;
    user_reg5 <= user_reg5_i;
    user_reg6 <= user_reg6_i;
    user_reg7 <= user_reg7_i;

    ----------------------------------------------------------------------------
    -- Rx instatiation
    -- -------------------------------------------------------------------------
    rx : uft_rx
        generic map (
            INCOMMING_PORT => INCOMMING_PORT,
            FIFO_DEPTH     => FIFO_DEPTH
        )
        port map (
            clk                    => clk,
            rst_n                  => rst_n,
            udp_rx_start           => udp_rx_start,
            udp_rx_hdr_is_valid    => udp_rx_hdr_is_valid,
            udp_rx_hdr_src_ip_addr => udp_rx_hdr_src_ip_addr,
            udp_rx_hdr_src_port    => udp_rx_hdr_src_port,
            udp_rx_hdr_dst_port    => udp_rx_hdr_dst_port,
            udp_rx_hdr_data_length => udp_rx_hdr_data_length,
            udp_rx_tdata           => udp_rx_tdata,
            udp_rx_tvalid          => udp_rx_tvalid,
            udp_rx_tlast           => udp_rx_tlast,
            M_AXIS_TVALID          => M_AXIS_TVALID,
            M_AXIS_TDATA           => M_AXIS_TDATA,
            M_AXIS_TLAST           => M_AXIS_TLAST,
            M_AXIS_TREADY          => M_AXIS_TREADY,
            rx_done                => rx_done,
            rx_row_num             => rx_row_num,
            rx_row_num_valid       => rx_row_num_valid,
            rx_row_size            => rx_row_size,
            rx_row_size_valid      => rx_row_size_valid,
            user_reg0              => user_reg0_i,
            user_reg1              => user_reg1_i,
            user_reg2              => user_reg2_i,
            user_reg3              => user_reg3_i,
            user_reg4              => user_reg4_i,
            user_reg5              => user_reg5_i,
            user_reg6              => user_reg6_i,
            user_reg7              => user_reg7_i,
            ack_cmd_nseq           => ack_cmd_nseq,
            ack_cmd_ft             => ack_cmd_ft,
            ack_cmd_nseq_done      => ack_cmd_nseq_done,
            ack_cmd_ft_done        => ack_cmd_ft_done,
            ack_seqnbr             => ack_seqnbr,
            ack_tcid               => ack_tcid,
            ack_dst_port           => ack_dst_port,
            ack_dst_ip             => ack_dst_ip
        );    

    ----------------------------------------------------------------------------
    -- UFT Tx instance
    -- -------------------------------------------------------------------------
    tx : uft_tx
        generic map (
            C_M_AXI_ADDR_WIDTH  => C_M_AXI_ADDR_WIDTH,
            C_M_AXI_DATA_WIDTH  => C_M_AXI_DATA_WIDTH,
            C_MAX_BURST_LEN     => C_MAX_BURST_LEN,
            C_ADDR_PIPE_DEPTH   => C_ADDR_PIPE_DEPTH,
            C_NATIVE_DATA_WIDTH => C_NATIVE_DATA_WIDTH,
            C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
            C_FAMILY            => C_FAMILY
        )
        port map (
            clk                    => clk,
            rst_n                  => rst_n,
            data_size              => tx_data_size,
            data_src_addr          => data_src_addr,
            tx_ready               => tx_ready_int,
            tx_start               => tx_start,
            dst_ip_addr            => tx_dst_ip_addr,
            dst_port               => tx_dst_port,
            udp_tx_start           => udp_tx_start,
            udp_tx_result          => udp_tx_result,
            udp_tx_hdr_dst_ip_addr => udp_tx_hdr_dst_ip_addr,
            udp_tx_hdr_dst_port    => udp_tx_hdr_dst_port,
            udp_tx_hdr_src_port    => udp_tx_hdr_src_port,
            udp_tx_hdr_data_length => udp_tx_hdr_data_length,
            udp_tx_hdr_checksum    => udp_tx_hdr_checksum,
            udp_tx_tvalid          => udp_tx_tvalid,
            udp_tx_tlast           => udp_tx_tlast,
            udp_tx_tdata           => udp_tx_tdata,
            udp_tx_tready          => udp_tx_tready,
            ip2bus_mstrd_req       => tx_ip2bus_mstrd_req,
            ip2bus_mstwr_req       => tx_ip2bus_mstwr_req,
            ip2bus_mst_addr        => tx_ip2bus_mst_addr,
            ip2bus_mst_length      => tx_ip2bus_mst_length,
            ip2bus_mst_be          => tx_ip2bus_mst_be,
            ip2bus_mst_type        => tx_ip2bus_mst_type,
            ip2bus_mst_lock        => tx_ip2bus_mst_lock,
            ip2bus_mst_reset       => tx_ip2bus_mst_reset,
            bus2ip_mst_cmdack      => tx_bus2ip_mst_cmdack,
            bus2ip_mst_cmplt       => tx_bus2ip_mst_cmplt,
            bus2ip_mst_error       => tx_bus2ip_mst_error,
            bus2ip_mst_rearbitrate => tx_bus2ip_mst_rearbitrate,
            bus2ip_mst_cmd_timeout => tx_bus2ip_mst_cmd_timeout,
            bus2ip_mstrd_d         => tx_bus2ip_mstrd_d,
            bus2ip_mstrd_rem       => tx_bus2ip_mstrd_rem,
            bus2ip_mstrd_sof_n     => tx_bus2ip_mstrd_sof_n,
            bus2ip_mstrd_eof_n     => tx_bus2ip_mstrd_eof_n,
            bus2ip_mstrd_src_rdy_n => tx_bus2ip_mstrd_src_rdy_n,
            bus2ip_mstrd_src_dsc_n => tx_bus2ip_mstrd_src_dsc_n,
            ip2bus_mstrd_dst_rdy_n => tx_ip2bus_mstrd_dst_rdy_n,
            ip2bus_mstrd_dst_dsc_n => tx_ip2bus_mstrd_dst_dsc_n,
            ip2bus_mstwr_d         => tx_ip2bus_mstwr_d,
            ip2bus_mstwr_rem       => tx_ip2bus_mstwr_rem,
            ip2bus_mstwr_sof_n     => tx_ip2bus_mstwr_sof_n,
            ip2bus_mstwr_eof_n     => tx_ip2bus_mstwr_eof_n,
            ip2bus_mstwr_src_rdy_n => tx_ip2bus_mstwr_src_rdy_n,
            ip2bus_mstwr_src_dsc_n => tx_ip2bus_mstwr_src_dsc_n,
            bus2ip_mstwr_dst_rdy_n => tx_bus2ip_mstwr_dst_rdy_n,
            bus2ip_mstwr_dst_dsc_n => tx_bus2ip_mstwr_dst_dsc_n,
            -- ack stuff
            ack_cmd_nseq           => ack_cmd_nseq,
            ack_cmd_ft             => ack_cmd_ft,
            ack_cmd_nseq_done      => ack_cmd_nseq_done,
            ack_cmd_ft_done        => ack_cmd_ft_done,
            ack_seqnbr             => ack_seqnbr,
            ack_tcid               => ack_tcid,
            ack_dst_port           => ack_dst_port,
            ack_dst_ip             => ack_dst_ip
        );       

    ----------------------------------------------------------------------------
    -- Instantiation of Axi Bus Interface S_AXI_CTRL
    -- -------------------------------------------------------------------------
    axi_ctrl_inst : axi_ctrl
        generic map (
            C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH
        )
        port map (
            user_reg0               => user_reg0_i,
            user_reg1               => user_reg1_i,
            user_reg2               => user_reg2_i,
            user_reg3               => user_reg3_i,
            user_reg4               => user_reg4_i,
            user_reg5               => user_reg5_i,
            user_reg6               => user_reg6_i,
            user_reg7               => user_reg7_i,
            tx_data_size            => tx_data_size,
            tx_data_src_addr        => data_src_addr,
            tx_ready                => tx_ready_int,
            tx_start                => tx_start,
            rx_data_dst_addr        => rx_data_dst_addr,
            rx_data_transaction_ctr => rx_data_transaction_ctr,
            S_AXI_ACLK  => s_axi_ctrl_aclk,
            S_AXI_ARESETN   => s_axi_ctrl_aresetn,
            S_AXI_AWADDR    => s_axi_ctrl_awaddr,
            S_AXI_AWPROT    => s_axi_ctrl_awprot,
            S_AXI_AWVALID   => s_axi_ctrl_awvalid,
            S_AXI_AWREADY   => s_axi_ctrl_awready,
            S_AXI_WDATA => s_axi_ctrl_wdata,
            S_AXI_WSTRB => s_axi_ctrl_wstrb,
            S_AXI_WVALID    => s_axi_ctrl_wvalid,
            S_AXI_WREADY    => s_axi_ctrl_wready,
            S_AXI_BRESP => s_axi_ctrl_bresp,
            S_AXI_BVALID    => s_axi_ctrl_bvalid,
            S_AXI_BREADY    => s_axi_ctrl_bready,
            S_AXI_ARADDR    => s_axi_ctrl_araddr,
            S_AXI_ARPROT    => s_axi_ctrl_arprot,
            S_AXI_ARVALID   => s_axi_ctrl_arvalid,
            S_AXI_ARREADY   => s_axi_ctrl_arready,
            S_AXI_RDATA => s_axi_ctrl_rdata,
            S_AXI_RRESP => s_axi_ctrl_rresp,
            S_AXI_RVALID    => s_axi_ctrl_rvalid,
            S_AXI_RREADY    => s_axi_ctrl_rready
        );    

    --data_src_addr <= x"08000000";
    tx_dst_ip_addr <= x"c0a8050a";      -- 192.168.5.10
    tx_dst_port <= x"08AE"; -- 2222
    tx_ready <= tx_ready_int;
    
    -- Settings
    -- -------------------------------------------------------------------------
    our_ip_address <= x"c0a80509";      -- 192.168.5.9
    our_mac_address <= x"002320212223";   

end architecture structural;
