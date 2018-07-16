-------------------------------------------------------------------------------
-- Title       : uft rx
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_rx.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Mon Jul 16 10:45:57 2018
-- Last update : Mon Jul 16 11:18:22 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 User Company Name
-------------------------------------------------------------------------------
-- Description: UFT receiving part
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity uft_rx is

    generic (
        INCOMMING_PORT : natural        := 42042;
        FIFO_DEPTH     : positive       := 366
    );
    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- Connection to UDP stack
        ------------------------------------------------------------------------
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

        -- Connection to User
        ------------------------------------------------------------------------
        M_AXIS_TVALID   : out   std_logic;
        M_AXIS_TDATA    : out   std_logic_vector(7 downto 0);
        M_AXIS_TLAST    : out   std_logic;
        M_AXIS_TREADY   : in    std_logic;

        rx_done            : out   std_logic;
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

        -- Connection to Ack
        ------------------------------------------------------------------------
        -- Commands for acknowledgment
        ack_cmd_nseq    : out std_logic; -- acknowledge a sequence
        ack_cmd_ft      : out std_logic; -- acknowledge a file transfer
        ack_cmd_nseq_done    : in std_logic;
        ack_cmd_ft_done      : in std_logic;
        -- data for commands
        ack_seqnbr              : out std_logic_vector (23 downto 0);
        ack_tcid                : out std_logic_vector ( 6 downto 0);
        ack_dst_port            : out std_logic_vector (15 downto 0);
        ack_dst_ip              : out std_logic_vector (31 downto 0)
    ) ;
end entity ; -- uft_rx

architecture structural of uft_rx is
    component uft_rx_disassemler is
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
            data_tdata             : out std_logic_vector( 7 downto 0);
            src_ip                 : out std_logic_vector (31 downto 0);
            src_port               : out std_logic_vector (15 downto 0)
        );
    end component uft_rx_disassemler;

    component utf_rx_mem_ctl is
        generic (
            FIFO_DEPTH          : positive                := 366
        );
        port (
            clk                : in  std_logic;
            rst_n              : in  std_logic;
            rx_done            : out std_logic := '0';
            is_data            : in  std_logic;
            data_tcid          : in  std_logic_vector( 6 downto 0);
            data_seq           : in  std_logic_vector(23 downto 0);
            data_meta_valid    : in  std_logic;
            data_tvalid        : in  std_logic;
            data_tlast         : in  std_logic;
            data_tdata         : in  std_logic_vector( 7 downto 0);
            is_command         : in  std_logic;
            command_code       : in  std_logic_vector(6 downto 0);
            command_data1      : in  std_logic_vector(23 downto 0);
            command_data2      : in  std_logic_vector(31 downto 0);
            command_data_valid : in  std_logic;
            rx_src_ip          : in  std_logic_vector (31 downto 0);
            rx_src_port        : in  std_logic_vector (15 downto 0);
            ack_cmd_nseq       : out std_logic;
            ack_cmd_ft         : out std_logic;
            ack_cmd_nseq_done  : in  std_logic;
            ack_cmd_ft_done    : in  std_logic;
            ack_seqnbr         : out std_logic_vector (23 downto 0);
            ack_tcid           : out std_logic_vector ( 6 downto 0);
            ack_dst_port       : out std_logic_vector (15 downto 0);
            ack_dst_ip         : out std_logic_vector (31 downto 0);
            M_AXIS_TVALID      : out std_logic;
            M_AXIS_TDATA       : out std_logic_vector(7 downto 0);
            M_AXIS_TLAST       : out std_logic;
            M_AXIS_TREADY      : in  std_logic;
            rx_row_num         : out std_logic_vector(31 downto 0);
            rx_row_num_valid   : out std_logic;
            rx_row_size        : out std_logic_vector(31 downto 0);
            rx_row_size_valid  : out std_logic;
            user_reg0          : out std_logic_vector(31 downto 0);
            user_reg1          : out std_logic_vector(31 downto 0);
            user_reg2          : out std_logic_vector(31 downto 0);
            user_reg3          : out std_logic_vector(31 downto 0);
            user_reg4          : out std_logic_vector(31 downto 0);
            user_reg5          : out std_logic_vector(31 downto 0);
            user_reg6          : out std_logic_vector(31 downto 0);
            user_reg7          : out std_logic_vector(31 downto 0)
        );
    end component utf_rx_mem_ctl;       


    -- connection between rx_disassembler and mem control
    signal is_command              : std_logic;
    signal command_code            : std_logic_vector(6 downto 0);
    signal command_data1           : std_logic_vector(23 downto 0);
    signal command_data2           : std_logic_vector(31 downto 0);
    signal command_data_valid      : std_logic;
    signal is_data                 : std_logic;
    signal data_tcid               : std_logic_vector( 6 downto 0);
    signal data_seq                : std_logic_vector(23 downto 0);
    signal data_meta_valid         : std_logic;
    signal data_tvalid             : std_logic;
    signal data_tlast              : std_logic;
    signal data_tdata              : std_logic_vector( 7 downto 0);

    -- unused ports
    signal src_ip      : std_logic_vector (31 downto 0);
    signal src_port    : std_logic_vector (15 downto 0);


begin
    rx_disassemler : uft_rx_disassemler
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
            data_tdata             => data_tdata,
            src_ip                 => src_ip,
            src_port               => src_port
        );


    rx_mem_ctl : utf_rx_mem_ctl
        generic map (
            FIFO_DEPTH          => FIFO_DEPTH
        )
        port map (
            clk                => clk,
            rst_n              => rst_n,
            rx_done            => rx_done,
            is_data            => is_data,
            data_tcid          => data_tcid,
            data_seq           => data_seq,
            data_meta_valid    => data_meta_valid,
            data_tvalid        => data_tvalid,
            data_tlast         => data_tlast,
            data_tdata         => data_tdata,
            is_command         => is_command,
            command_code       => command_code,
            command_data1      => command_data1,
            command_data2      => command_data2,
            command_data_valid => command_data_valid,
            rx_src_ip          => src_ip,
            rx_src_port        => src_port,
            ack_cmd_nseq       => ack_cmd_nseq,
            ack_cmd_ft         => ack_cmd_ft,
            ack_cmd_nseq_done  => ack_cmd_nseq_done,
            ack_cmd_ft_done    => ack_cmd_ft_done,
            ack_seqnbr         => ack_seqnbr,
            ack_tcid           => ack_tcid,
            ack_dst_port       => ack_dst_port,
            ack_dst_ip         => ack_dst_ip,
            M_AXIS_TVALID      => M_AXIS_TVALID,
            M_AXIS_TDATA       => M_AXIS_TDATA,
            M_AXIS_TLAST       => M_AXIS_TLAST,
            M_AXIS_TREADY      => M_AXIS_TREADY,
            rx_row_num         => rx_row_num,
            rx_row_num_valid   => rx_row_num_valid,
            rx_row_size        => rx_row_size,
            rx_row_size_valid  => rx_row_size_valid,
            user_reg0          => user_reg0,
            user_reg1          => user_reg1,
            user_reg2          => user_reg2,
            user_reg3          => user_reg3,
            user_reg4          => user_reg4,
            user_reg5          => user_reg5,
            user_reg6          => user_reg6,
            user_reg7          => user_reg7
        );    


end architecture ; -- structural