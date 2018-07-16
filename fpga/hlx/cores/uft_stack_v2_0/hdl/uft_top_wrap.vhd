-------------------------------------------------------------------------------
-- Title       : UFT Top Module Wrapper
-- Project     : diip
-------------------------------------------------------------------------------
-- File        : uft_top_wrap.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Wed Nov 22 15:53:25 2017
-- Last update : Mon Jul 16 09:38:07 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Combines uft top module with axi master ipif
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------
library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

use work.uft_pkg.all;

entity uft_top_wrap is
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

        -- Rx pixel
        -- ---------------------------------------------------------------------
        M_AXIS_TVALID   : out   std_logic;
        M_AXIS_TDATA    : out   std_logic_vector(8 downto 0);
        M_AXIS_TLAST    : out   std_logic;
        M_AXIS_TREADY   : in    std_logic;

        rx_row_num         : out std_logic_vector(31 downto 0);
        rx_row_num_valid   : out std_logic;
        rx_row_size        : out std_logic_vector(31 downto 0);
        rx_row_size_valid  : out std_logic;
        rx_user_0          : out std_logic_vector(31 downto 0);
        rx_user_0_valid    : out std_logic;

        rx_done        : out  std_logic;

        -- Tx pixel
        -- ---------------------------------------------------------------------
        S_AXIS_TREADY   : out   std_logic;
        S_AXIS_TDATA    : in    std_logic_vector(8 downto 0);
        S_AXIS_TLAST    : in    std_logic;
        S_AXIS_TVALID   : in    std_logic;

        tx_row_num         : in std_logic_vector(31 downto 0);
        tx_row_size        : in std_logic_vector(31 downto 0);
        tx_row_size_valid  : out std_logic;

        tx_ready        : out  std_logic;
        tx_start        : out  std_logic;
        
        -- Controll
        -- ---------------------------------------------------------------------
        our_ip_address      : out STD_LOGIC_VECTOR (31 downto 0);
        our_mac_address         : out std_logic_vector (47 downto 0);

        -- UDP IP Stack Receiver
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

        -- UDP IP Stack Transmitter
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
        udp_tx_tready               : in  std_logic
	) ;
end entity ; -- uft_top_wrap

architecture structural of uft_top_wrap is
	----------------------------------------------------------------------------
    -- UFT Top component declaration
    -- -------------------------------------------------------------------------
    component uft_top is
        generic (
            INCOMMING_PORT      : natural                 := 42042;
            FIFO_DEPTH          : positive                := 366;
            C_M_AXI_ADDR_WIDTH  : integer range 32 to 64  := 32;
            C_M_AXI_DATA_WIDTH  : integer range 32 to 256 := 32;
            C_MAX_BURST_LEN     : Integer range 16 to 256 := 16;
            C_ADDR_PIPE_DEPTH   : Integer range 1 to 14   := 1;
            C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
            C_LENGTH_WIDTH      : INTEGER range 12 to 20  := 12;
            C_FAMILY            : string                  := "artix7";
            C_S_AXI_DATA_WIDTH  : integer                 := 32;
            C_S_AXI_ADDR_WIDTH  : integer                 := 6
        );
        port (
            clk                       : in  std_logic;
            rst_n                     : in  std_logic;
            our_ip_address            : out STD_LOGIC_VECTOR (31 downto 0);
            our_mac_address           : out std_logic_vector (47 downto 0);
            rx_done                   : out std_logic;
            tx_ready                   : out std_logic;
            udp_rx_start              : in  std_logic;
            udp_rx_hdr_is_valid       : in  std_logic;
            udp_rx_hdr_src_ip_addr    : in  std_logic_vector (31 downto 0);
            udp_rx_hdr_src_port       : in  std_logic_vector (15 downto 0);
            udp_rx_hdr_dst_port       : in  std_logic_vector (15 downto 0);
            udp_rx_hdr_data_length    : in  std_logic_vector (15 downto 0);
            udp_rx_tdata              : in  std_logic_vector (7 downto 0);
            udp_rx_tvalid             : in  std_logic;
            udp_rx_tlast              : in  std_logic;
            udp_tx_start              : out std_logic;
            udp_tx_result             : in  std_logic_vector (1 downto 0);
            udp_tx_hdr_dst_ip_addr    : out std_logic_vector (31 downto 0);
            udp_tx_hdr_dst_port       : out std_logic_vector (15 downto 0);
            udp_tx_hdr_src_port       : out std_logic_vector (15 downto 0);
            udp_tx_hdr_data_length    : out std_logic_vector (15 downto 0);
            udp_tx_hdr_checksum       : out std_logic_vector (15 downto 0);
            udp_tx_tvalid             : out std_logic;
            udp_tx_tlast              : out std_logic;
            udp_tx_tdata              : out std_logic_vector (7 downto 0);
            udp_tx_tready             : in  std_logic;
            ip2bus_mstrd_req          : out std_logic;
            ip2bus_mstwr_req          : out std_logic;
            ip2bus_mst_addr           : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
            ip2bus_mst_length         : out std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
            ip2bus_mst_be             : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
            ip2bus_mst_type           : out std_logic;
            ip2bus_mst_lock           : out std_logic;
            ip2bus_mst_reset          : out std_logic;
            bus2ip_mst_cmdack         : in  std_logic;
            bus2ip_mst_cmplt          : in  std_logic;
            bus2ip_mst_error          : in  std_logic;
            bus2ip_mst_rearbitrate    : in  std_logic;
            bus2ip_mst_cmd_timeout    : in  std_logic;
            bus2ip_mstrd_d            : in  std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 );
            bus2ip_mstrd_rem          : in  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
            bus2ip_mstrd_sof_n        : in  std_logic;
            bus2ip_mstrd_eof_n        : in  std_logic;
            bus2ip_mstrd_src_rdy_n    : in  std_logic;
            bus2ip_mstrd_src_dsc_n    : in  std_logic;
            ip2bus_mstrd_dst_rdy_n    : out std_logic;
            ip2bus_mstrd_dst_dsc_n    : out std_logic;
            ip2bus_mstwr_d            : out std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
            ip2bus_mstwr_rem          : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
            ip2bus_mstwr_sof_n        : out std_logic;
            ip2bus_mstwr_eof_n        : out std_logic;
            ip2bus_mstwr_src_rdy_n    : out std_logic;
            ip2bus_mstwr_src_dsc_n    : out std_logic;
            bus2ip_mstwr_dst_rdy_n    : in  std_logic;
            bus2ip_mstwr_dst_dsc_n    : in  std_logic;
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
            s_axi_ctrl_aclk           : in  std_logic;
            s_axi_ctrl_aresetn        : in  std_logic;
            s_axi_ctrl_awaddr         : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            s_axi_ctrl_awprot         : in  std_logic_vector(2 downto 0);
            s_axi_ctrl_awvalid        : in  std_logic;
            s_axi_ctrl_awready        : out std_logic;
            s_axi_ctrl_wdata          : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            s_axi_ctrl_wstrb          : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
            s_axi_ctrl_wvalid         : in  std_logic;
            s_axi_ctrl_wready         : out std_logic;
            s_axi_ctrl_bresp          : out std_logic_vector(1 downto 0);
            s_axi_ctrl_bvalid         : out std_logic;
            s_axi_ctrl_bready         : in  std_logic;
            s_axi_ctrl_araddr         : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            s_axi_ctrl_arprot         : in  std_logic_vector(2 downto 0);
            s_axi_ctrl_arvalid        : in  std_logic;
            s_axi_ctrl_arready        : out std_logic;
            s_axi_ctrl_rdata          : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            s_axi_ctrl_rresp          : out std_logic_vector(1 downto 0);
            s_axi_ctrl_rvalid         : out std_logic;
            s_axi_ctrl_rready         : in  std_logic
        );
    end component uft_top;    

	----------------------------------------------------------------------------
    -- AXI master burst component declaration
    -- -------------------------------------------------------------------------
    component axi_master_burst is
        generic (
            C_M_AXI_ADDR_WIDTH  : integer range 32 to 64  := 32;
            C_M_AXI_DATA_WIDTH  : integer range 32 to 256 := 32;
            C_MAX_BURST_LEN     : Integer range 16 to 256 := 16;
            C_ADDR_PIPE_DEPTH   : Integer range 1 to 14   := 1;
            C_NATIVE_DATA_WIDTH : INTEGER range 32 to 128 := 32;
            C_LENGTH_WIDTH      : INTEGER range 12 to 20  := 12;
            C_FAMILY            : string                  := "virtex7"
        );
        port (
            m_axi_aclk             : in  std_logic;
            m_axi_aresetn          : in  std_logic;
            md_error               : out std_logic;
            m_axi_arready          : in  std_logic;
            m_axi_arvalid          : out std_logic;
            m_axi_araddr           : out std_logic_vector (C_M_AXI_ADDR_WIDTH-1 downto 0);
            m_axi_arlen            : out std_logic_vector(7 downto 0);
            m_axi_arsize           : out std_logic_vector(2 downto 0);
            m_axi_arburst          : out std_logic_vector(1 downto 0);
            m_axi_arprot           : out std_logic_vector(2 downto 0);
            m_axi_arcache          : out std_logic_vector(3 downto 0);
            m_axi_rready           : out std_logic;
            m_axi_rvalid           : in  std_logic;
            m_axi_rdata            : in  std_logic_vector (C_M_AXI_DATA_WIDTH-1 downto 0);
            m_axi_rresp            : in  std_logic_vector(1 downto 0);
            m_axi_rlast            : in  std_logic;
            m_axi_awready          : in  std_logic;
            m_axi_awvalid          : out std_logic;
            m_axi_awaddr           : out std_logic_vector (C_M_AXI_ADDR_WIDTH-1 downto 0);
            m_axi_awlen            : out std_logic_vector(7 downto 0);
            m_axi_awsize           : out std_logic_vector(2 downto 0);
            m_axi_awburst          : out std_logic_vector(1 downto 0);
            m_axi_awprot           : out std_logic_vector(2 downto 0);
            m_axi_awcache          : out std_logic_vector(3 downto 0);
            m_axi_wready           : in  std_logic;
            m_axi_wvalid           : out std_logic;
            m_axi_wdata            : out std_logic_vector (C_M_AXI_DATA_WIDTH-1 downto 0);
            m_axi_wstrb            : out std_logic_vector ((C_M_AXI_DATA_WIDTH/8)-1 downto 0);
            m_axi_wlast            : out std_logic;
            m_axi_bready           : out std_logic;
            m_axi_bvalid           : in  std_logic;
            m_axi_bresp            : in  std_logic_vector(1 downto 0);
            ip2bus_mstrd_req       :     In std_logic;
            ip2bus_mstwr_req       :     In std_logic;
            ip2bus_mst_addr        : in  std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
            ip2bus_mst_length      : in  std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
            ip2bus_mst_be          : in  std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
            ip2bus_mst_type        : in  std_logic;
            ip2bus_mst_lock        :     In std_logic;
            ip2bus_mst_reset       :     In std_logic;
            bus2ip_mst_cmdack      :     Out std_logic;
            bus2ip_mst_cmplt       :     Out std_logic;
            bus2ip_mst_error       :     Out std_logic;
            bus2ip_mst_rearbitrate :     Out std_logic;
            bus2ip_mst_cmd_timeout : out std_logic;
            bus2ip_mstrd_d         : out std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 );
            bus2ip_mstrd_rem       : out std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
            bus2ip_mstrd_sof_n     :     Out std_logic;
            bus2ip_mstrd_eof_n     :     Out std_logic;
            bus2ip_mstrd_src_rdy_n :     Out std_logic;
            bus2ip_mstrd_src_dsc_n :     Out std_logic;
            ip2bus_mstrd_dst_rdy_n :     In std_logic;
            ip2bus_mstrd_dst_dsc_n :     In std_logic;
            ip2bus_mstwr_d         :     In std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
            ip2bus_mstwr_rem       :     In std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
            ip2bus_mstwr_sof_n     :     In std_logic;
            ip2bus_mstwr_eof_n     :     In std_logic;
            ip2bus_mstwr_src_rdy_n :     In std_logic;
            ip2bus_mstwr_src_dsc_n :     In std_logic;
            bus2ip_mstwr_dst_rdy_n :     Out std_logic;
            bus2ip_mstwr_dst_dsc_n :     Out std_logic
        );
    end component axi_master_burst;

	----------------------------------------------------------------------------
    -- Signals uft_top -> amb tx
    -- -------------------------------------------------------------------------
	signal ip2bus_tx_mstrd_req       : std_logic;
	signal ip2bus_tx_mstwr_req       : std_logic;
	signal ip2bus_tx_mst_addr        : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
	signal ip2bus_tx_mst_length      : std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
	signal ip2bus_tx_mst_be          : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
	signal ip2bus_tx_mst_type        : std_logic;
	signal ip2bus_tx_mst_lock        : std_logic;
	signal ip2bus_tx_mst_reset       : std_logic;
	signal bus2ip_tx_mst_cmdack      : std_logic;
	signal bus2ip_tx_mst_cmplt       : std_logic;
	signal bus2ip_tx_mst_error       : std_logic;
	signal bus2ip_tx_mst_rearbitrate : std_logic;
	signal bus2ip_tx_mst_cmd_timeout : std_logic;
	signal bus2ip_tx_mstrd_d         : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 );
	signal bus2ip_tx_mstrd_rem       : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
	signal bus2ip_tx_mstrd_sof_n     : std_logic;
	signal bus2ip_tx_mstrd_eof_n     : std_logic;
	signal bus2ip_tx_mstrd_src_rdy_n : std_logic;
	signal bus2ip_tx_mstrd_src_dsc_n : std_logic;
	signal ip2bus_tx_mstrd_dst_rdy_n : std_logic;
	signal ip2bus_tx_mstrd_dst_dsc_n : std_logic;
	signal ip2bus_tx_mstwr_d         : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
	signal ip2bus_tx_mstwr_rem       : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
	signal ip2bus_tx_mstwr_sof_n     : std_logic;
	signal ip2bus_tx_mstwr_eof_n     : std_logic;
	signal ip2bus_tx_mstwr_src_rdy_n : std_logic;
	signal ip2bus_tx_mstwr_src_dsc_n : std_logic;
	signal bus2ip_tx_mstwr_dst_rdy_n : std_logic;
	signal bus2ip_tx_mstwr_dst_dsc_n : std_logic;
	----------------------------------------------------------------------------
    -- Signals uft_top -> amb rx
    -- -------------------------------------------------------------------------
	signal ip2bus_rx_mstrd_req       : std_logic;
	signal ip2bus_rx_mstwr_req       : std_logic;
	signal ip2bus_rx_mst_addr        : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
	signal ip2bus_rx_mst_length      : std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
	signal ip2bus_rx_mst_be          : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
	signal ip2bus_rx_mst_type        : std_logic;
	signal ip2bus_rx_mst_lock        : std_logic;
	signal ip2bus_rx_mst_reset       : std_logic;
	signal bus2ip_rx_mst_cmdack      : std_logic;
	signal bus2ip_rx_mst_cmplt       : std_logic;
	signal bus2ip_rx_mst_error       : std_logic;
	signal bus2ip_rx_mst_rearbitrate : std_logic;
	signal bus2ip_rx_mst_cmd_timeout : std_logic;
	signal bus2ip_rx_mstrd_d         : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0 );
	signal bus2ip_rx_mstrd_rem       : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
	signal bus2ip_rx_mstrd_sof_n     : std_logic;
	signal bus2ip_rx_mstrd_eof_n     : std_logic;
	signal bus2ip_rx_mstrd_src_rdy_n : std_logic;
	signal bus2ip_rx_mstrd_src_dsc_n : std_logic;
	signal ip2bus_rx_mstrd_dst_rdy_n : std_logic;
	signal ip2bus_rx_mstrd_dst_dsc_n : std_logic;
	signal ip2bus_rx_mstwr_d         : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
	signal ip2bus_rx_mstwr_rem       : std_logic_vector((C_NATIVE_DATA_WIDTH/8)-1 downto 0);
	signal ip2bus_rx_mstwr_sof_n     : std_logic;
	signal ip2bus_rx_mstwr_eof_n     : std_logic;
	signal ip2bus_rx_mstwr_src_rdy_n : std_logic;
	signal ip2bus_rx_mstwr_src_dsc_n : std_logic;
	signal bus2ip_rx_mstwr_dst_rdy_n : std_logic;
	signal bus2ip_rx_mstwr_dst_dsc_n : std_logic;

begin

	----------------------------------------------------------------------------
    -- UFT top instance
    -- -------------------------------------------------------------------------
    uft_top_i : uft_top
        generic map (
            INCOMMING_PORT      => INCOMMING_PORT,
            FIFO_DEPTH          => FIFO_DEPTH,
            C_M_AXI_ADDR_WIDTH  => C_M_AXI_ADDR_WIDTH,
            C_M_AXI_DATA_WIDTH  => C_M_AXI_DATA_WIDTH,
            C_MAX_BURST_LEN     => C_MAX_BURST_LEN,
            C_ADDR_PIPE_DEPTH   => C_ADDR_PIPE_DEPTH,
            C_NATIVE_DATA_WIDTH => C_NATIVE_DATA_WIDTH,
            C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
            C_FAMILY            => C_FAMILY,
            C_S_AXI_DATA_WIDTH  => C_S_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH  => C_S_AXI_ADDR_WIDTH
        )
        port map (
            clk                       => clk,
            rst_n                     => rst_n,
            our_ip_address            => our_ip_address,
            our_mac_address           => our_mac_address,
            rx_done                   => rx_done,
            tx_ready                  => tx_ready,
            udp_rx_start              => udp_rx_start,
            udp_rx_hdr_is_valid       => udp_rx_hdr_is_valid,
            udp_rx_hdr_src_ip_addr    => udp_rx_hdr_src_ip_addr,
            udp_rx_hdr_src_port       => udp_rx_hdr_src_port,
            udp_rx_hdr_dst_port       => udp_rx_hdr_dst_port,
            udp_rx_hdr_data_length    => udp_rx_hdr_data_length,
            udp_rx_tdata              => udp_rx_tdata,
            udp_rx_tvalid             => udp_rx_tvalid,
            udp_rx_tlast              => udp_rx_tlast,
            udp_tx_start              => udp_tx_start,
            udp_tx_result             => udp_tx_result,
            udp_tx_hdr_dst_ip_addr    => udp_tx_hdr_dst_ip_addr,
            udp_tx_hdr_dst_port       => udp_tx_hdr_dst_port,
            udp_tx_hdr_src_port       => udp_tx_hdr_src_port,
            udp_tx_hdr_data_length    => udp_tx_hdr_data_length,
            udp_tx_hdr_checksum       => udp_tx_hdr_checksum,
            udp_tx_tvalid             => udp_tx_tvalid,
            udp_tx_tlast              => udp_tx_tlast,
            udp_tx_tdata              => udp_tx_tdata,
            udp_tx_tready             => udp_tx_tready,
            ip2bus_mstrd_req          => ip2bus_rx_mstrd_req,
            ip2bus_mstwr_req          => ip2bus_rx_mstwr_req,
            ip2bus_mst_addr           => ip2bus_rx_mst_addr,
            ip2bus_mst_length         => ip2bus_rx_mst_length,
            ip2bus_mst_be             => ip2bus_rx_mst_be,
            ip2bus_mst_type           => ip2bus_rx_mst_type,
            ip2bus_mst_lock           => ip2bus_rx_mst_lock,
            ip2bus_mst_reset          => ip2bus_rx_mst_reset,
            bus2ip_mst_cmdack         => bus2ip_rx_mst_cmdack,
            bus2ip_mst_cmplt          => bus2ip_rx_mst_cmplt,
            bus2ip_mst_error          => bus2ip_rx_mst_error,
            bus2ip_mst_rearbitrate    => bus2ip_rx_mst_rearbitrate,
            bus2ip_mst_cmd_timeout    => bus2ip_rx_mst_cmd_timeout,
            bus2ip_mstrd_d            => bus2ip_rx_mstrd_d,
            bus2ip_mstrd_rem          => bus2ip_rx_mstrd_rem,
            bus2ip_mstrd_sof_n        => bus2ip_rx_mstrd_sof_n,
            bus2ip_mstrd_eof_n        => bus2ip_rx_mstrd_eof_n,
            bus2ip_mstrd_src_rdy_n    => bus2ip_rx_mstrd_src_rdy_n,
            bus2ip_mstrd_src_dsc_n    => bus2ip_rx_mstrd_src_dsc_n,
            ip2bus_mstrd_dst_rdy_n    => ip2bus_rx_mstrd_dst_rdy_n,
            ip2bus_mstrd_dst_dsc_n    => ip2bus_rx_mstrd_dst_dsc_n,
            ip2bus_mstwr_d            => ip2bus_rx_mstwr_d,
            ip2bus_mstwr_rem          => ip2bus_rx_mstwr_rem,
            ip2bus_mstwr_sof_n        => ip2bus_rx_mstwr_sof_n,
            ip2bus_mstwr_eof_n        => ip2bus_rx_mstwr_eof_n,
            ip2bus_mstwr_src_rdy_n    => ip2bus_rx_mstwr_src_rdy_n,
            ip2bus_mstwr_src_dsc_n    => ip2bus_rx_mstwr_src_dsc_n,
            bus2ip_mstwr_dst_rdy_n    => bus2ip_rx_mstwr_dst_rdy_n,
            bus2ip_mstwr_dst_dsc_n    => bus2ip_rx_mstwr_dst_dsc_n,
            tx_ip2bus_mstrd_req       => ip2bus_tx_mstrd_req,
            tx_ip2bus_mstwr_req       => ip2bus_tx_mstwr_req,
            tx_ip2bus_mst_addr        => ip2bus_tx_mst_addr,
            tx_ip2bus_mst_length      => ip2bus_tx_mst_length,
            tx_ip2bus_mst_be          => ip2bus_tx_mst_be,
            tx_ip2bus_mst_type        => ip2bus_tx_mst_type,
            tx_ip2bus_mst_lock        => ip2bus_tx_mst_lock,
            tx_ip2bus_mst_reset       => ip2bus_tx_mst_reset,
            tx_bus2ip_mst_cmdack      => bus2ip_tx_mst_cmdack,
            tx_bus2ip_mst_cmplt       => bus2ip_tx_mst_cmplt,
            tx_bus2ip_mst_error       => bus2ip_tx_mst_error,
            tx_bus2ip_mst_rearbitrate => bus2ip_tx_mst_rearbitrate,
            tx_bus2ip_mst_cmd_timeout => bus2ip_tx_mst_cmd_timeout,
            tx_bus2ip_mstrd_d         => bus2ip_tx_mstrd_d,
            tx_bus2ip_mstrd_rem       => bus2ip_tx_mstrd_rem,
            tx_bus2ip_mstrd_sof_n     => bus2ip_tx_mstrd_sof_n,
            tx_bus2ip_mstrd_eof_n     => bus2ip_tx_mstrd_eof_n,
            tx_bus2ip_mstrd_src_rdy_n => bus2ip_tx_mstrd_src_rdy_n,
            tx_bus2ip_mstrd_src_dsc_n => bus2ip_tx_mstrd_src_dsc_n,
            tx_ip2bus_mstrd_dst_rdy_n => ip2bus_tx_mstrd_dst_rdy_n,
            tx_ip2bus_mstrd_dst_dsc_n => ip2bus_tx_mstrd_dst_dsc_n,
            tx_ip2bus_mstwr_d         => ip2bus_tx_mstwr_d,
            tx_ip2bus_mstwr_rem       => ip2bus_tx_mstwr_rem,
            tx_ip2bus_mstwr_sof_n     => ip2bus_tx_mstwr_sof_n,
            tx_ip2bus_mstwr_eof_n     => ip2bus_tx_mstwr_eof_n,
            tx_ip2bus_mstwr_src_rdy_n => ip2bus_tx_mstwr_src_rdy_n,
            tx_ip2bus_mstwr_src_dsc_n => ip2bus_tx_mstwr_src_dsc_n,
            tx_bus2ip_mstwr_dst_rdy_n => bus2ip_tx_mstwr_dst_rdy_n,
            tx_bus2ip_mstwr_dst_dsc_n => bus2ip_tx_mstwr_dst_dsc_n,
            s_axi_ctrl_aclk           => s_axi_ctrl_aclk,
            s_axi_ctrl_aresetn        => s_axi_ctrl_aresetn,
            s_axi_ctrl_awaddr         => s_axi_ctrl_awaddr,
            s_axi_ctrl_awprot         => s_axi_ctrl_awprot,
            s_axi_ctrl_awvalid        => s_axi_ctrl_awvalid,
            s_axi_ctrl_awready        => s_axi_ctrl_awready,
            s_axi_ctrl_wdata          => s_axi_ctrl_wdata,
            s_axi_ctrl_wstrb          => s_axi_ctrl_wstrb,
            s_axi_ctrl_wvalid         => s_axi_ctrl_wvalid,
            s_axi_ctrl_wready         => s_axi_ctrl_wready,
            s_axi_ctrl_bresp          => s_axi_ctrl_bresp,
            s_axi_ctrl_bvalid         => s_axi_ctrl_bvalid,
            s_axi_ctrl_bready         => s_axi_ctrl_bready,
            s_axi_ctrl_araddr         => s_axi_ctrl_araddr,
            s_axi_ctrl_arprot         => s_axi_ctrl_arprot,
            s_axi_ctrl_arvalid        => s_axi_ctrl_arvalid,
            s_axi_ctrl_arready        => s_axi_ctrl_arready,
            s_axi_ctrl_rdata          => s_axi_ctrl_rdata,
            s_axi_ctrl_rresp          => s_axi_ctrl_rresp,
            s_axi_ctrl_rvalid         => s_axi_ctrl_rvalid,
            s_axi_ctrl_rready         => s_axi_ctrl_rready
        );	

	----------------------------------------------------------------------------
    -- AXI master burst Rx instance
    -- -------------------------------------------------------------------------
    amb_rx : axi_master_burst
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
            m_axi_aclk             => m_axi_tx_aclk,
            m_axi_aresetn          => m_axi_tx_aresetn,
            md_error               => open,
            m_axi_arready          => m_axi_tx_arready,
            m_axi_arvalid          => m_axi_tx_arvalid,
            m_axi_araddr           => m_axi_tx_araddr,
            m_axi_arlen            => m_axi_tx_arlen,
            m_axi_arsize           => m_axi_tx_arsize,
            m_axi_arburst          => m_axi_tx_arburst,
            m_axi_arprot           => m_axi_tx_arprot,
            m_axi_arcache          => m_axi_tx_arcache,
            m_axi_rready           => m_axi_tx_rready,
            m_axi_rvalid           => m_axi_tx_rvalid,
            m_axi_rdata            => m_axi_tx_rdata,
            m_axi_rresp            => m_axi_tx_rresp,
            m_axi_rlast            => m_axi_tx_rlast,
            m_axi_awready          => m_axi_tx_awready,
            m_axi_awvalid          => m_axi_tx_awvalid,
            m_axi_awaddr           => m_axi_tx_awaddr,
            m_axi_awlen            => m_axi_tx_awlen,
            m_axi_awsize           => m_axi_tx_awsize,
            m_axi_awburst          => m_axi_tx_awburst,
            m_axi_awprot           => m_axi_tx_awprot,
            m_axi_awcache          => m_axi_tx_awcache,
            m_axi_wready           => m_axi_tx_wready,
            m_axi_wvalid           => m_axi_tx_wvalid,
            m_axi_wdata            => m_axi_tx_wdata,
            m_axi_wstrb            => m_axi_tx_wstrb,
            m_axi_wlast            => m_axi_tx_wlast,
            m_axi_bready           => m_axi_tx_bready,
            m_axi_bvalid           => m_axi_tx_bvalid,
            m_axi_bresp            => m_axi_tx_bresp,
            ip2bus_mstrd_req       => ip2bus_tx_mstrd_req,
            ip2bus_mstwr_req       => ip2bus_tx_mstwr_req,
            ip2bus_mst_addr        => ip2bus_tx_mst_addr,
            ip2bus_mst_length      => ip2bus_tx_mst_length,
            ip2bus_mst_be          => ip2bus_tx_mst_be,
            ip2bus_mst_type        => ip2bus_tx_mst_type,
            ip2bus_mst_lock        => ip2bus_tx_mst_lock,
            ip2bus_mst_reset       => ip2bus_tx_mst_reset,
            bus2ip_mst_cmdack      => bus2ip_tx_mst_cmdack,
            bus2ip_mst_cmplt       => bus2ip_tx_mst_cmplt,
            bus2ip_mst_error       => bus2ip_tx_mst_error,
            bus2ip_mst_rearbitrate => bus2ip_tx_mst_rearbitrate,
            bus2ip_mst_cmd_timeout => bus2ip_tx_mst_cmd_timeout,
            bus2ip_mstrd_d         => bus2ip_tx_mstrd_d,
            bus2ip_mstrd_rem       => bus2ip_tx_mstrd_rem,
            bus2ip_mstrd_sof_n     => bus2ip_tx_mstrd_sof_n,
            bus2ip_mstrd_eof_n     => bus2ip_tx_mstrd_eof_n,
            bus2ip_mstrd_src_rdy_n => bus2ip_tx_mstrd_src_rdy_n,
            bus2ip_mstrd_src_dsc_n => bus2ip_tx_mstrd_src_dsc_n,
            ip2bus_mstrd_dst_rdy_n => ip2bus_tx_mstrd_dst_rdy_n,
            ip2bus_mstrd_dst_dsc_n => ip2bus_tx_mstrd_dst_dsc_n,
            ip2bus_mstwr_d         => ip2bus_tx_mstwr_d,
            ip2bus_mstwr_rem       => ip2bus_tx_mstwr_rem,
            ip2bus_mstwr_sof_n     => ip2bus_tx_mstwr_sof_n,
            ip2bus_mstwr_eof_n     => ip2bus_tx_mstwr_eof_n,
            ip2bus_mstwr_src_rdy_n => ip2bus_tx_mstwr_src_rdy_n,
            ip2bus_mstwr_src_dsc_n => ip2bus_tx_mstwr_src_dsc_n,
            bus2ip_mstwr_dst_rdy_n => bus2ip_tx_mstwr_dst_rdy_n,
            bus2ip_mstwr_dst_dsc_n => bus2ip_tx_mstwr_dst_dsc_n
        );    

	----------------------------------------------------------------------------
    -- AXI master burst Tx instance
    -- -------------------------------------------------------------------------
    amb_tx : axi_master_burst
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
            m_axi_aclk             => m_axi_rx_aclk,
            m_axi_aresetn          => m_axi_rx_aresetn,
            md_error               => open,
            m_axi_arready          => m_axi_rx_arready,
            m_axi_arvalid          => m_axi_rx_arvalid,
            m_axi_araddr           => m_axi_rx_araddr,
            m_axi_arlen            => m_axi_rx_arlen,
            m_axi_arsize           => m_axi_rx_arsize,
            m_axi_arburst          => m_axi_rx_arburst,
            m_axi_arprot           => m_axi_rx_arprot,
            m_axi_arcache          => m_axi_rx_arcache,
            m_axi_rready           => m_axi_rx_rready,
            m_axi_rvalid           => m_axi_rx_rvalid,
            m_axi_rdata            => m_axi_rx_rdata,
            m_axi_rresp            => m_axi_rx_rresp,
            m_axi_rlast            => m_axi_rx_rlast,
            m_axi_awready          => m_axi_rx_awready,
            m_axi_awvalid          => m_axi_rx_awvalid,
            m_axi_awaddr           => m_axi_rx_awaddr,
            m_axi_awlen            => m_axi_rx_awlen,
            m_axi_awsize           => m_axi_rx_awsize,
            m_axi_awburst          => m_axi_rx_awburst,
            m_axi_awprot           => m_axi_rx_awprot,
            m_axi_awcache          => m_axi_rx_awcache,
            m_axi_wready           => m_axi_rx_wready,
            m_axi_wvalid           => m_axi_rx_wvalid,
            m_axi_wdata            => m_axi_rx_wdata,
            m_axi_wstrb            => m_axi_rx_wstrb,
            m_axi_wlast            => m_axi_rx_wlast,
            m_axi_bready           => m_axi_rx_bready,
            m_axi_bvalid           => m_axi_rx_bvalid,
            m_axi_bresp            => m_axi_rx_bresp,
            ip2bus_mstrd_req       => ip2bus_rx_mstrd_req,
            ip2bus_mstwr_req       => ip2bus_rx_mstwr_req,
            ip2bus_mst_addr        => ip2bus_rx_mst_addr,
            ip2bus_mst_length      => ip2bus_rx_mst_length,
            ip2bus_mst_be          => ip2bus_rx_mst_be,
            ip2bus_mst_type        => ip2bus_rx_mst_type,
            ip2bus_mst_lock        => ip2bus_rx_mst_lock,
            ip2bus_mst_reset       => ip2bus_rx_mst_reset,
            bus2ip_mst_cmdack      => bus2ip_rx_mst_cmdack,
            bus2ip_mst_cmplt       => bus2ip_rx_mst_cmplt,
            bus2ip_mst_error       => bus2ip_rx_mst_error,
            bus2ip_mst_rearbitrate => bus2ip_rx_mst_rearbitrate,
            bus2ip_mst_cmd_timeout => bus2ip_rx_mst_cmd_timeout,
            bus2ip_mstrd_d         => bus2ip_rx_mstrd_d,
            bus2ip_mstrd_rem       => bus2ip_rx_mstrd_rem,
            bus2ip_mstrd_sof_n     => bus2ip_rx_mstrd_sof_n,
            bus2ip_mstrd_eof_n     => bus2ip_rx_mstrd_eof_n,
            bus2ip_mstrd_src_rdy_n => bus2ip_rx_mstrd_src_rdy_n,
            bus2ip_mstrd_src_dsc_n => bus2ip_rx_mstrd_src_dsc_n,
            ip2bus_mstrd_dst_rdy_n => ip2bus_rx_mstrd_dst_rdy_n,
            ip2bus_mstrd_dst_dsc_n => ip2bus_rx_mstrd_dst_dsc_n,
            ip2bus_mstwr_d         => ip2bus_rx_mstwr_d,
            ip2bus_mstwr_rem       => ip2bus_rx_mstwr_rem,
            ip2bus_mstwr_sof_n     => ip2bus_rx_mstwr_sof_n,
            ip2bus_mstwr_eof_n     => ip2bus_rx_mstwr_eof_n,
            ip2bus_mstwr_src_rdy_n => ip2bus_rx_mstwr_src_rdy_n,
            ip2bus_mstwr_src_dsc_n => ip2bus_rx_mstwr_src_dsc_n,
            bus2ip_mstwr_dst_rdy_n => bus2ip_rx_mstwr_dst_rdy_n,
            bus2ip_mstwr_dst_dsc_n => bus2ip_rx_mstwr_dst_dsc_n
        );    

end architecture ; -- structural