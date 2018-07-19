-------------------------------------------------------------------------------
-- Title       : UFT Top Module
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_top.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Nov 22 15:53:25 2017
-- Last update : Thu Jul 19 16:11:32 2018
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
        FIFO_DEPTH : positive := 366 -- (1464/4)
    );
    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- RX user interface
        -- ---------------------------------------------------------------------
        m_axis_tvalid   : out   std_logic;
        m_axis_tdata    : out   std_logic_vector(7 downto 0);
        m_axis_tlast    : out   std_logic;
        m_axis_tready   : in    std_logic;

        rx_done            : out  std_logic; 
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

        -- TX user interface
        -- ---------------------------------------------------------------------
        s_axis_tvalid              : in  std_logic;
        s_axis_tlast               : in  std_logic;
        s_axis_tdata               : in  std_logic_vector (7 downto 0);
        s_axis_tready              : out std_logic;
        
        tx_start                   : in  std_logic;
        tx_ready                   : out std_logic;
        tx_row_num                 : in  std_logic_vector (31 downto 0);
        tx_data_size               : in  std_logic_vector (31 downto 0);

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

        -- To UDP misc
        -- ---------------------------------------------------------------------
        our_ip_address          : out STD_LOGIC_VECTOR (31 downto 0);
        our_mac_address         : out std_logic_vector (47 downto 0)

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
            m_axis_tvalid          : out std_logic;
            m_axis_tdata           : out std_logic_vector(7 downto 0);
            m_axis_tlast           : out std_logic;
            m_axis_tready          : in  std_logic;
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
        port (
            clk                    : in  std_logic;
            rst_n                  : in  std_logic;
            data_size              : in  std_logic_vector(31 downto 0);
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
            s_axis_tvalid          : in  std_logic;
            s_axis_tlast           : in  std_logic;
            s_axis_tdata           : in  std_logic_vector (7 downto 0);
            s_axis_tready          : out std_logic
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
begin

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
            m_axis_tvalid          => m_axis_tvalid,
            m_axis_tdata           => m_axis_tdata,
            m_axis_tlast           => m_axis_tlast,
            m_axis_tready          => m_axis_tready,
            rx_done                => rx_done,
            rx_row_num             => rx_row_num,
            rx_row_num_valid       => rx_row_num_valid,
            rx_row_size            => rx_row_size,
            rx_row_size_valid      => rx_row_size_valid,
            user_reg0              => user_reg0,
            user_reg1              => user_reg1,
            user_reg2              => user_reg2,
            user_reg3              => user_reg3,
            user_reg4              => user_reg4,
            user_reg5              => user_reg5,
            user_reg6              => user_reg6,
            user_reg7              => user_reg7,
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
        port map (
            clk                    => clk,
            rst_n                  => rst_n,
            data_size              => tx_data_size,
            tx_ready               => tx_ready,
            tx_start               => tx_start,
            dst_ip_addr            => tx_dst_ip_addr,
            dst_port               => tx_dst_port,
            
            -- ack stuff
            ack_cmd_nseq           => ack_cmd_nseq,
            ack_cmd_ft             => ack_cmd_ft,
            ack_cmd_nseq_done      => ack_cmd_nseq_done,
            ack_cmd_ft_done        => ack_cmd_ft_done,
            ack_seqnbr             => ack_seqnbr,
            ack_tcid               => ack_tcid,
            ack_dst_port           => ack_dst_port,
            ack_dst_ip             => ack_dst_ip,

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

            s_axis_tvalid          => s_axis_tvalid,
            s_axis_tlast           => s_axis_tlast,
            s_axis_tdata           => s_axis_tdata,
            s_axis_tready          => s_axis_tready
        );
    
    -- Settings
    -- -------------------------------------------------------------------------
    tx_dst_ip_addr      <= x"c0a8050a";      -- 192.168.5.10
    tx_dst_port         <= x"08AE"; -- 2222
    our_ip_address      <= x"c0a80509";      -- 192.168.5.9
    our_mac_address     <= x"002320212223";   

end architecture structural;
