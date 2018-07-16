-------------------------------------------------------------------------------
-- Title       : uft_tx
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_tx
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Mon Nov 27 15:32:28 2017
-- Last update : Mon Jul 16 16:24:51 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Handles file transmission for the udp file transfer protocol
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.uft_pkg.all;

entity uft_tx is
    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;
        
        -- User IO
        -- ---------------------------------------------------------------------
        -- number of bytes to send ( Max 4GB = 4'294'967'296 Bytes)
        data_size       : in  std_logic_vector(31 downto 0);
        -- Indicates if the system is ready for a new file transfer
        tx_ready        : out std_logic;
        -- assert high to start a transmission
        tx_start        : in  std_logic;
        -- IP
        dst_ip_addr      : in std_logic_vector (31 downto 0);
        dst_port         : in std_logic_vector (15 downto 0);

        -- Commands for acknowledgment
        ack_cmd_nseq    : in std_logic; -- acknowledge a sequence
        ack_cmd_ft      : in std_logic; -- acknowledge a file transfer
        ack_cmd_nseq_done    : out std_logic;
        ack_cmd_ft_done      : out std_logic;
        -- data for commands
        ack_seqnbr              : in std_logic_vector (23 downto 0);
        ack_tcid                : in std_logic_vector ( 6 downto 0);
        ack_dst_port            : in std_logic_vector (15 downto 0);
        ack_dst_ip              : in std_logic_vector (31 downto 0);
        
        -- UDP Transmitter
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

        -- TX slave axis
        -- ---------------------------------------------------------------------
        s_axis_tvalid              : in  std_logic;
        s_axis_tlast               : in  std_logic;
        s_axis_tdata               : in  std_logic_vector (7 downto 0);
        s_axis_tready              : out std_logic
    );
end entity uft_tx;

architecture structural of uft_tx is
    ----------------------------------------------------------------------------
    -- Component declaration
    -- -------------------------------------------------------------------------
    component uft_tx_control is
        generic (
            C_PACKET_DELAY_US  : integer range 1 to 150 := 100
        );
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
            udp_tx_hdr_data_length : out std_logic_vector (15 downto 0);
            udp_tx_hdr_checksum    : out std_logic_vector (15 downto 0);
            udp_tx_hdr_dst_ip_addr : out std_logic_vector (31 downto 0);
            udp_tx_hdr_dst_port    : out std_logic_vector (15 downto 0);
            udp_tx_hdr_src_port    : out std_logic_vector (15 downto 0);
            arb_sel                : out std_logic;
            cmd_tcid               : out std_logic_vector (6 downto 0);
            cmd_en_start           : out std_logic;
            cmd_en_ackseq          : out std_logic;
            cmd_en_ackft           : out std_logic;
            cmd_done               : in  std_logic;
            cmd_nseq               : out std_logic_vector (31 downto 0);
            cmd_seqnbr             : out std_logic_vector (23 downto 0);
            data_tcid              : out std_logic_vector (6 downto 0);
            data_seq               : out std_logic_vector (23 downto 0);
            packet_data_size       : out std_logic_vector (10 downto 0);
            data_start             : out std_logic;
            data_done              : in  std_logic
        );
    end component uft_tx_control;     

    ----------------------------------------------------------------------------
    -- Component declaration
    -- -------------------------------------------------------------------------
    component uft_tx_cmd_assembler is
        port (
            clk       : in  std_logic;
            rst_n     : in  std_logic;
            data_size : in  std_logic_vector (31 downto 0);
            tcid      : in  std_logic_vector (6 downto 0);
            seqnbr    : in  std_logic_vector (23 downto 0);
            en_start  : in  std_logic;
            en_ackseq : in  std_logic;
            en_ackft  : in  std_logic;
            done      : out std_logic;
            tx_tvalid : out std_logic;
            tx_tlast  : out std_logic;
            tx_tdata  : out std_logic_vector (7 downto 0);
            tx_tready : in  std_logic
        );
    end component uft_tx_cmd_assembler;    

    ----------------------------------------------------------------------------
    -- Component declaration
    -- -------------------------------------------------------------------------
    component uft_tx_data_assembler is
        port (
            clk           : in  std_logic;
            rst_n         : in  std_logic;
            tcid          : in  std_logic_vector (6 downto 0);
            seq           : in  std_logic_vector (23 downto 0);
            size          : in  std_logic_vector (10 downto 0);
            start         : in  std_logic;
            done          : out std_logic;
            s_axis_tvalid : in  std_logic;
            s_axis_tlast  : in  std_logic;
            s_axis_tdata  : in  std_logic_vector (7 downto 0);
            s_axis_tready : out std_logic;
            tx_tvalid     : out std_logic;
            tx_tlast      : out std_logic;
            tx_tdata      : out std_logic_vector (7 downto 0);
            tx_tready     : in  std_logic
        );
    end component uft_tx_data_assembler;    

    ----------------------------------------------------------------------------
    -- Component declaration
    -- -------------------------------------------------------------------------
    component uft_tx_arbiter is
        port (
            clk      : in  std_logic;
            rst_n    : in  std_logic;
            sel      : in  std_logic;
            tvalid_0 : in  std_logic;
            tlast_0  : in  std_logic;
            tdata_0  : in  std_logic_vector (7 downto 0);
            tready_0 : out std_logic;
            tvalid_1 : in  std_logic;
            tlast_1  : in  std_logic;
            tdata_1  : in  std_logic_vector (7 downto 0);
            tready_1 : out std_logic;
            tvalid   : out std_logic;
            tlast    : out std_logic;
            tdata    : out std_logic_vector (7 downto 0);
            tready   : in  std_logic
        );
    end component uft_tx_arbiter;       

    ----------------------------------------------------------------------------
    -- Signals
    -- -------------------------------------------------------------------------
    -- Ctrl to data and command
    signal cmd_tcid                 : std_logic_vector (6 downto 0);
    signal cmd_en_start             : std_logic; -- generate start packet
    signal cmd_en_ackseq             : std_logic; 
    signal cmd_en_ackft             : std_logic; 
    signal cmd_done                 : std_logic; -- asserted if packet is sent
    signal cmd_nseq                 : std_logic_vector (31 downto 0);
    signal cmd_seqnbr               : std_logic_vector (23 downto 0);
    signal data_tcid                : std_logic_vector (6 downto 0);
    signal data_seq                 : std_logic_vector (23 downto 0);
    signal packet_data_size         : std_logic_vector (10 downto 0);
    signal data_start               : std_logic;
    signal data_done                : std_logic;

    -- Command packet generator
    signal cmd_tvalid               : std_logic;
    signal cmd_tlast                : std_logic;
    signal cmd_tdata                : std_logic_vector (7 downto 0);
    signal cmd_tready               : std_logic;
    -- Data packet generator
    signal data_tvalid               : std_logic;
    signal data_tlast                : std_logic;
    signal data_tdata                : std_logic_vector (7 downto 0);
    signal data_tready               : std_logic;
    -- arbiter
    signal arb_sel                   : std_logic;
begin
    

    ----------------------------------------------------------------------------
    -- Control instance
    -- -------------------------------------------------------------------------
    control : entity work.uft_tx_control
        generic map (
            C_PACKET_DELAY_US  => 1
        )
        port map (
            clk                    => clk,
            rst_n                  => rst_n,
            data_size              => data_size,
            tx_ready               => tx_ready,
            tx_start               => tx_start,
            dst_ip_addr            => dst_ip_addr,
            dst_port               => dst_port,
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
            udp_tx_hdr_data_length => udp_tx_hdr_data_length,
            udp_tx_hdr_checksum    => udp_tx_hdr_checksum,
            udp_tx_hdr_dst_ip_addr => udp_tx_hdr_dst_ip_addr,
            udp_tx_hdr_dst_port    => udp_tx_hdr_dst_port,
            udp_tx_hdr_src_port    => udp_tx_hdr_src_port,
            arb_sel                => arb_sel,
            cmd_tcid               => cmd_tcid,
            cmd_en_start           => cmd_en_start,
            cmd_en_ackseq          => cmd_en_ackseq,
            cmd_en_ackft           => cmd_en_ackft,
            cmd_done               => cmd_done,
            cmd_nseq               => cmd_nseq,
            cmd_seqnbr             => cmd_seqnbr,
            data_tcid              => data_tcid,
            data_seq               => data_seq,
            packet_data_size       => packet_data_size,
            data_start             => data_start,
            data_done              => data_done
        );           

    ----------------------------------------------------------------------------
    -- Command packet instance
    -- -------------------------------------------------------------------------
    cmd_asm : uft_tx_cmd_assembler
        port map (
            clk       => clk,
            rst_n     => rst_n,
            data_size => cmd_nseq,
            tcid      => cmd_tcid,
            seqnbr    => cmd_seqnbr,
            en_start  => cmd_en_start,
            en_ackseq => cmd_en_ackseq,
            en_ackft  => cmd_en_ackft,
            done      => cmd_done,
            tx_tvalid => cmd_tvalid,
            tx_tlast  => cmd_tlast,
            tx_tdata  => cmd_tdata,
            tx_tready => cmd_tready
        );
    ----------------------------------------------------------------------------
    -- Data packet instance
    -- -------------------------------------------------------------------------
    data_asm : uft_tx_data_assembler
        port map (
            clk                    => clk,
            rst_n                  => rst_n,
            tcid                   => data_tcid,
            seq                    => data_seq,
            size                   => packet_data_size,
            start                  => data_start,
            done                   => data_done,
            s_axis_tvalid => s_axis_tvalid,
            s_axis_tlast  => s_axis_tlast,
            s_axis_tdata  => s_axis_tdata,
            s_axis_tready => s_axis_tready,
            tx_tvalid     => data_tvalid,
            tx_tlast      => data_tlast,
            tx_tdata      => data_tdata,
            tx_tready     => data_tready
        );       

    ----------------------------------------------------------------------------
    -- Arbiter instance
    -- -------------------------------------------------------------------------
    arb : uft_tx_arbiter
        port map (
            clk      => clk,
            rst_n    => rst_n,
            sel      => arb_sel,
            tvalid_0 => cmd_tvalid,
            tlast_0  => cmd_tlast,
            tdata_0  => cmd_tdata,
            tready_0 => cmd_tready,
            tvalid_1 => data_tvalid,
            tlast_1  => data_tlast,
            tdata_1  => data_tdata,
            tready_1 => data_tready,
            tvalid   => udp_tx_tvalid,
            tlast    => udp_tx_tlast,
            tdata    => udp_tx_tdata,
            tready   => udp_tx_tready
        );    
end architecture structural;