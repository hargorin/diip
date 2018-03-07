-------------------------------------------------------------------------------
-- Title       : UFT Top Module
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_top.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Nov 22 15:53:25 2017
-- Last update : Sat Dec  2 16:19:55 2017
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
        C_FAMILY            : string                  := "artix7"
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

        -- number of bytes to send ( Max 4GB = 4'294'967'296 Bytes)
        tx_data_size       : in  std_logic_vector(31 downto 0);
        -- Data source address
        
        -- Indicates if the system is ready for a new file transfer
        tx_ready        : out std_logic;
        -- assert high to start a transmission
        tx_start        : in  std_logic;

        -- Receiver
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

        -- Transmitter
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

        -- RX Memory IP Interface
        -- ---------------------------------------------------------------------
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
        bus2ip_mstwr_dst_dsc_n : in  std_logic;  

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
        tx_bus2ip_mstwr_dst_dsc_n : in  std_logic   
    );
end entity uft_top;

architecture structural of uft_top is
    ----------------------------------------------------------------------------
    -- rx component declaration
    -- -------------------------------------------------------------------------
    component uft_rx is
        generic (
            INCOMMING_PORT : natural := 42042
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
            is_command             : out std_logic;
            command_code           : out std_logic_vector(6 downto 0);
            command_data1          : out std_logic_vector(23 downto 0);
            command_data2          : out std_logic_vector(31 downto 0);
            command_data_valid     : out std_logic;
            is_data                : out std_logic;
            data_tcid              : out std_logic_vector( 6 downto 0);
            data_seq               : out std_logic_vector(23 downto 0);
            data_meta_valid        : out std_logic;
            data_tvalid            : out std_logic;
            data_tlast             : out std_logic;
            data_tdata             : out std_logic_vector( 7 downto 0)
        );
    end component uft_rx;    

    ----------------------------------------------------------------------------
    -- rx mem controller declaration
    -- -------------------------------------------------------------------------
    component utf_rx_mem_ctl is
        generic (
            FIFO_DEPTH          : positive                := 366;
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
            is_data                : in  std_logic;
            data_tcid              : in  std_logic_vector( 6 downto 0);
            data_seq               : in  std_logic_vector(23 downto 0);
            data_meta_valid        : in  std_logic;
            data_tvalid            : in  std_logic;
            data_tlast             : in  std_logic;
            data_tdata             : in  std_logic_vector( 7 downto 0);
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
    end component utf_rx_mem_ctl;  

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
            src_port               : in  std_logic_vector (15 downto 0);
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
    signal dst_ip_addr      : std_logic_vector (31 downto 0);
    signal dst_port         : std_logic_vector (15 downto 0);
    signal src_port         : std_logic_vector (15 downto 0);  
begin
        
    ----------------------------------------------------------------------------
    -- Rx instatiation
    -- -------------------------------------------------------------------------
    rx : uft_rx
        generic map (
            INCOMMING_PORT => INCOMMING_PORT
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
            is_command             => is_command,
            command_code           => command_code,
            command_data1          => command_data1,
            command_data2          => command_data2,
            command_data_valid     => command_data_valid,
            is_data                => is_data,
            data_tcid              => data_tcid,
            data_seq               => data_seq,
            data_meta_valid        => data_meta_valid,
            data_tvalid            => data_tvalid,
            data_tlast             => data_tlast,
            data_tdata             => data_tdata
        ); 

    ----------------------------------------------------------------------------
    -- Rx Mem Ctrl instance
    -- -------------------------------------------------------------------------
    rx_mem_ctl : utf_rx_mem_ctl
        generic map (
            FIFO_DEPTH          => FIFO_DEPTH,
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
            is_data                => is_data,
            data_tcid              => data_tcid,
            data_seq               => data_seq,
            data_meta_valid        => data_meta_valid,
            data_tvalid            => data_tvalid,
            data_tlast             => data_tlast,
            data_tdata             => data_tdata,
            ip2bus_mstrd_req       => ip2bus_mstrd_req,
            ip2bus_mstwr_req       => ip2bus_mstwr_req,
            ip2bus_mst_addr        => ip2bus_mst_addr,
            ip2bus_mst_length      => ip2bus_mst_length,
            ip2bus_mst_be          => ip2bus_mst_be,
            ip2bus_mst_type        => ip2bus_mst_type,
            ip2bus_mst_lock        => ip2bus_mst_lock,
            ip2bus_mst_reset       => ip2bus_mst_reset,
            bus2ip_mst_cmdack      => bus2ip_mst_cmdack,
            bus2ip_mst_cmplt       => bus2ip_mst_cmplt,
            bus2ip_mst_error       => bus2ip_mst_error,
            bus2ip_mst_rearbitrate => bus2ip_mst_rearbitrate,
            bus2ip_mst_cmd_timeout => bus2ip_mst_cmd_timeout,
            bus2ip_mstrd_d         => bus2ip_mstrd_d,
            bus2ip_mstrd_rem       => bus2ip_mstrd_rem,
            bus2ip_mstrd_sof_n     => bus2ip_mstrd_sof_n,
            bus2ip_mstrd_eof_n     => bus2ip_mstrd_eof_n,
            bus2ip_mstrd_src_rdy_n => bus2ip_mstrd_src_rdy_n,
            bus2ip_mstrd_src_dsc_n => bus2ip_mstrd_src_dsc_n,
            ip2bus_mstrd_dst_rdy_n => ip2bus_mstrd_dst_rdy_n,
            ip2bus_mstrd_dst_dsc_n => ip2bus_mstrd_dst_dsc_n,
            ip2bus_mstwr_d         => ip2bus_mstwr_d,
            ip2bus_mstwr_rem       => ip2bus_mstwr_rem,
            ip2bus_mstwr_sof_n     => ip2bus_mstwr_sof_n,
            ip2bus_mstwr_eof_n     => ip2bus_mstwr_eof_n,
            ip2bus_mstwr_src_rdy_n => ip2bus_mstwr_src_rdy_n,
            ip2bus_mstwr_src_dsc_n => ip2bus_mstwr_src_dsc_n,
            bus2ip_mstwr_dst_rdy_n => bus2ip_mstwr_dst_rdy_n,
            bus2ip_mstwr_dst_dsc_n => bus2ip_mstwr_dst_dsc_n
        ); 

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
            tx_ready               => tx_ready,
            tx_start               => tx_start,
            dst_ip_addr            => dst_ip_addr,
            dst_port               => dst_port,
            src_port               => src_port,
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
            bus2ip_mstwr_dst_dsc_n => tx_bus2ip_mstwr_dst_dsc_n
        ); 
    data_src_addr <= x"08000000";
    dst_ip_addr <= x"c0a8050a";      -- 192.168.5.10
    dst_port <= x"08AE"; -- 2222
    src_port <= x"08Af"; -- 2223

    -- Settings
    -- -------------------------------------------------------------------------
    our_ip_address <= x"c0a80509";      -- 192.168.5.9
    our_mac_address <= x"002320212223";   

end architecture structural;
