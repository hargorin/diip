-------------------------------------------------------------------------------
-- Title       : UFT TX Control
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_tx_ctrl.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Wed Nov 29 11:43:40 2017
-- Last update : Fri Apr 20 13:24:15 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Controls the UFT Transmission blocks cmd assembler and data
-- assembler and arbiter
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uft_tx_control is
    generic (
        C_M_AXI_ADDR_WIDTH  : integer range 32 to  64  := 32;
        C_PACKET_DELAY_US   : integer range  1 to 150  := 100
    );
    port (
        -- Control
        -- ---------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;
        
        -- User IO
        -- ---------------------------------------------------------------------
        -- number of bytes to send ( Max 4GB = 4'294'967'296 Bytes)
        data_size       : in  std_logic_vector(31 downto 0);
        -- Data source address
        data_src_addr   : in std_logic_vector (C_M_AXI_ADDR_WIDTH-1 downto 0);
        -- Indicates if the system is ready for a new file transfer
        tx_ready        : out std_logic;
        -- assert high to start a transmission
        tx_start        : in  std_logic;
        -- destination information
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

        -- UDP Stack
        -- ---------------------------------------------------------------------
        udp_tx_start                : out std_logic;
        udp_tx_result               : in  std_logic_vector (1 downto 0);
        udp_tx_hdr_data_length      : out std_logic_vector (15 downto 0);
        udp_tx_hdr_checksum         : out std_logic_vector (15 downto 0);

        udp_tx_hdr_dst_ip_addr      : out std_logic_vector (31 downto 0);
        udp_tx_hdr_dst_port         : out std_logic_vector (15 downto 0);
        udp_tx_hdr_src_port         : out std_logic_vector (15 downto 0);

        -- Arbiter
        -- ---------------------------------------------------------------------
        arb_sel         : out std_logic;

        -- Connection to cmd assembler
        -- ---------------------------------------------------------------------
        cmd_tcid            : out std_logic_vector (6 downto 0);
        cmd_en_start        : out std_logic; -- generate start packet
        cmd_en_ackseq        : out std_logic; 
        cmd_en_ackft        : out std_logic; 
        cmd_done            : in  std_logic; -- asserted if packet is sent
        cmd_nseq            : out std_logic_vector (31 downto 0);
        cmd_seqnbr          : out std_logic_vector (23 downto 0);

        -- Connection to data assembler
        -- ---------------------------------------------------------------------
        -- Data source address
        data_data_src_addr      : out std_logic_vector (C_M_AXI_ADDR_WIDTH-1 downto 0);
        -- Transaction ID 
        data_tcid               : out std_logic_vector (6 downto 0);
        -- packet sequence number
        data_seq                : out std_logic_vector (23 downto 0);
        -- number of bytes to send ( Max 1464 bytes per packet)
        packet_data_size         : out std_logic_vector (10 downto 0);
        -- Assert high for 1 clk to start generation
        data_start              : out std_logic;
        data_done               : in  std_logic -- asserted if packet is sent
    );
end entity uft_tx_control;

architecture structural of uft_tx_control is
    type state_type is (IDLE, CMD, CMD_WAIT, DATA, DATA_WAIT, DATA_WAIT_DONE, DELAY, CPLT,
        ACK_SEQ, ACK_SEQ_WAIT, ACK_FT, ACK_FT_WAIT);
    signal current_state : state_type;
    signal next_state : state_type;
    -- number of data sequences to be sent
    signal nseq : unsigned (23 downto 0);
    signal nseq_ctr : unsigned (23 downto 0);
    -- stores the current transaction id
    signal tcid : unsigned(6 downto 0) := (others => '0');

    signal ack_cmd_nseq_latch : std_logic;
    signal ack_cmd_ft_latch : std_logic;

    signal packet_data_size_int : std_logic_vector (10 downto 0);
    signal data_size_int : integer;
    signal remaining_bytes : unsigned(31 downto 0) := (others => '0');
    signal data_offset : unsigned(31 downto 0) := (others => '0');

    -- Number of bytes per Packet. Use a power of 2: The start command packet 
    --  sends the number of data packets to be sent. For this calculation, the
    --  data_size is divided by c_nbytes_per_packet. When using a pow of 2 this
    --  division can be done by shifting 
    constant c_nbytes_per_packet : integer := 1024;
    constant c_nbytes_per_packet_div4 : integer := c_nbytes_per_packet / 4;
    constant c_src_port : std_logic_vector (15 downto 0) := x"a43b"; -- 42043

    -- Delay between packets
    signal delay_ctr : integer range 0 to 15000;
    constant c_packet_delay : integer := C_PACKET_DELAY_US*(125); -- 100us delay between packets
begin
    ----------------------------------------------------------------------------
    -- next state process
    -- -------------------------------------------------------------------------
    p_ns : process( clk )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                current_state <= IDLE;
            else
                current_state <= next_state;
            end if;
        end if;
    end process ; -- p_ns

    ----------------------------------------------------------------------------
    -- ack latch process. latches ack requests
    -- -------------------------------------------------------------------------
    p_ack_latch : process (clk)
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                ack_cmd_nseq_latch <= '0';
                ack_cmd_ft_latch <= '0';
            else
                -- latch the ack requests if requested
                if ack_cmd_nseq = '1' then
                    ack_cmd_nseq_latch <= '1';
                end if;
                if ack_cmd_ft = '1' then
                    ack_cmd_ft_latch <= '1';
                end if;
                -- clear them if in their wait state
                if current_state = ACK_SEQ_WAIT then
                    ack_cmd_nseq_latch <= '0';
                end if;
                if current_state = ACK_FT_WAIT then
                    ack_cmd_ft_latch <= '0';
                end if;

            end if;
        end if;
    end process; -- p_ack_latch
    

    ----------------------------------------------------------------------------
    p_next_state : process( current_state, tx_start, cmd_done, data_done, 
        remaining_bytes, delay_ctr, ack_cmd_nseq_latch, ack_cmd_ft_latch)
        variable old_state : state_type := IDLE;
        variable data_was_done : std_logic := '0';
    ----------------------------------------------------------------------------
    begin
        next_state <= current_state;
        case (current_state) is
            when IDLE => 
                if ack_cmd_nseq_latch = '1' then
                    old_state := IDLE;
                    next_state <= ACK_SEQ;
                elsif ack_cmd_ft_latch = '1' then
                    old_state := IDLE;
                    next_state <= ACK_FT;
                elsif tx_start = '1' then
                    next_state <= CMD;
                end if;
            when CMD => 
                next_state <= CMD_WAIT;
            when CMD_WAIT => 
                if cmd_done = '1' then
                    next_state <= DATA;
                end if;
            when DATA => 
                next_state <= DATA_WAIT;
            when DATA_WAIT => 
                if data_done = '1' then
                    next_state <= DATA_WAIT_DONE;
                end if;
            when DATA_WAIT_DONE => 
                -- interrupt regular transfer with ack package
                if ack_cmd_nseq_latch = '1' then
                    data_was_done := '1';
                    old_state := DATA_WAIT_DONE;
                    next_state <= ACK_SEQ;
                elsif ack_cmd_ft_latch = '1' then
                    data_was_done := '1';
                    old_state := DATA_WAIT_DONE;
                    next_state <= ACK_FT;
                elsif remaining_bytes = 0 then
                    next_state <= CPLT;
                elsif c_packet_delay /= 0 then
                    next_state <= DELAY;
                else
                    next_state <= DATA;
                end if;
            when DELAY => 
                if delay_ctr >= (c_packet_delay-1) then
                    next_state <= DATA;
                end if;
            when CPLT => 
                next_state <= IDLE;
            when ACK_SEQ => 
                next_state <= ACK_SEQ_WAIT;
            when ACK_SEQ_WAIT => 
                -- if done change to old state
                if cmd_done = '1' then
                    next_state <= old_state;
                end if;
            when ACK_FT => 
                next_state <= ACK_FT_WAIT;
            when ACK_FT_WAIT => 
                -- if done change to old state
                if cmd_done = '1' then
                    next_state <= old_state;
                end if;
        end case;
    end process ; -- p_next_state
    ----------------------------------------------------------------------------
    p_out : process( current_state )
    ----------------------------------------------------------------------------
    begin
        tx_ready <= '0';
        cmd_en_start <= '0';
        cmd_en_ackseq <= '0';
        cmd_en_ackft <= '0';
        data_start <= '0';
        arb_sel <= '0';
        udp_tx_start <= '0';

        -- output transaction id
        cmd_tcid <= std_logic_vector(tcid);
        data_tcid <= std_logic_vector(tcid);

        case (current_state) is
            when IDLE =>
                tx_ready <= '1';
            when CMD => 
                udp_tx_start <= '1';
                cmd_en_start <= '1';
            when CMD_WAIT => 
            when DATA => 
                udp_tx_start <= '1';
                arb_sel <= '1';
                data_start <= '1';
            when DATA_WAIT => 
                arb_sel <= '1';
            when DATA_WAIT_DONE => 
            when DELAY => 
            when CPLT => 
            when ACK_SEQ => 
                cmd_tcid <= ack_tcid;
                udp_tx_start <= '1';
                cmd_en_ackseq <= '1';
            when ACK_SEQ_WAIT => 
                cmd_tcid <= ack_tcid;
            when ACK_FT =>  
                cmd_tcid <= ack_tcid;
                udp_tx_start <= '1';
                cmd_en_ackft <= '1';
            when ACK_FT_WAIT => 
                cmd_tcid <= ack_tcid;
        end case;
    end process ; -- p_out
    ----------------------------------------------------------------------------
    p_seq : process( clk )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                tcid <= (others => '0');
                data_offset <= (others => '0');
                remaining_bytes <= (others => '0');
                nseq_ctr <= (others => '0');
            else
                case (current_state) is
                    when IDLE =>
                        data_offset <= (others => '0');
                        remaining_bytes <= unsigned(data_size);
                        nseq_ctr <= (others => '0');
                    when CMD => 
                    when CMD_WAIT => 
                    when DATA => 
                    when DATA_WAIT_DONE => 
                    when DATA_WAIT => 
                        if data_done = '1' then
                        --if remaining_bytes > c_nbytes_per_packet then
                            --remaining_bytes <= remaining_bytes - c_nbytes_per_packet;
                            remaining_bytes <= remaining_bytes - unsigned(packet_data_size_int);
                            nseq_ctr <= nseq_ctr + 1;
                            data_offset <= data_offset + c_nbytes_per_packet;
                        --end if;
                        end if;
                    when DELAY => 
                    when CPLT => 
                        if tcid = 127 then
                            tcid <= (others => '0');
                        else
                            tcid <= tcid + 1;
                        end if;
                    when ACK_SEQ => 
                    when ACK_SEQ_WAIT => 
                    when ACK_FT =>  
                    when ACK_FT_WAIT => 
                end case;
            end if;
        end if;
    end process ; -- p_seq


    ----------------------------------------------------------------------------
    -- Delay counter process
    -- -------------------------------------------------------------------------
    p_delay : process( clk )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                delay_ctr <= 0;
            else
                if current_state = DELAY then
                    delay_ctr <= delay_ctr + 1;
                else
                    delay_ctr <= 0;
                end if;
            end if;
        end if;
    end process ; -- p_delay

    ----------------------------------------------------------------------------
    p_udp_header_len : process( current_state, packet_data_size_int )
    ----------------------------------------------------------------------------
    begin
        udp_tx_hdr_data_length <= (others => '0');
        case (current_state) is
            when IDLE =>
            when CMD => 
                udp_tx_hdr_data_length <= std_logic_vector(to_unsigned(34 ,udp_tx_hdr_data_length'length));
            when CMD_WAIT => 
                -- 8 UDP, 8 UFT, 26 padding
                udp_tx_hdr_data_length <= std_logic_vector(to_unsigned(34 ,udp_tx_hdr_data_length'length));
            when DATA => 
                udp_tx_hdr_data_length <= std_logic_vector(to_unsigned(to_integer(unsigned(packet_data_size_int))+4 ,udp_tx_hdr_data_length'length));
            when DATA_WAIT => 
                udp_tx_hdr_data_length <= std_logic_vector(to_unsigned(to_integer(unsigned(packet_data_size_int))+4 ,udp_tx_hdr_data_length'length));
            when DATA_WAIT_DONE => 
            when DELAY => 
            when CPLT => 
            when ACK_SEQ => 
                udp_tx_hdr_data_length <= std_logic_vector(to_unsigned(34 ,udp_tx_hdr_data_length'length));
            when ACK_SEQ_WAIT => 
                udp_tx_hdr_data_length <= std_logic_vector(to_unsigned(34 ,udp_tx_hdr_data_length'length));
            when ACK_FT =>  
                udp_tx_hdr_data_length <= std_logic_vector(to_unsigned(34 ,udp_tx_hdr_data_length'length));
            when ACK_FT_WAIT => 
                udp_tx_hdr_data_length <= std_logic_vector(to_unsigned(34 ,udp_tx_hdr_data_length'length));
        end case;
    end process ; -- p_udp_header_len


    ----------------------------------------------------------------------------
    -- Output for ack done
    -- -------------------------------------------------------------------------
    p_dack_done_out: process( clk )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                ack_cmd_nseq_done <= '1';
                ack_cmd_ft_done <= '1';
            else
                if ack_cmd_nseq_latch = '1' then
                    ack_cmd_nseq_done <= '0';
                elsif current_state = ACK_SEQ_WAIT and cmd_done = '1' then
                    ack_cmd_nseq_done <= '1';
                end if;
                if ack_cmd_ft_latch = '1' then
                    ack_cmd_ft_done <= '0';
                elsif current_state = ACK_FT_WAIT and cmd_done = '1' then
                    ack_cmd_ft_done <= '1';
                end if;

            end if;
        end if;
    end process ; -- p_ack_done_out

    ----------------------------------------------------------------------------
    -- UDP tx header outputs
    -- IP and port from input if command or data, but ip and port from ack source
    -- during ack
    -- -------------------------------------------------------------------------
    p_udp_hdr_out : process (current_state, dst_port, dst_ip_addr,
        ack_dst_port, ack_dst_ip)
    ----------------------------------------------------------------------------
    begin
        udp_tx_hdr_dst_port <= dst_port;
        udp_tx_hdr_src_port <= c_src_port;
        udp_tx_hdr_dst_ip_addr <= dst_ip_addr;

        -- ignore checksum for now
        udp_tx_hdr_checksum <= (others => '0');

        case (current_state) is
            when IDLE =>
                udp_tx_hdr_dst_port <= (others => '0');
                udp_tx_hdr_src_port <= (others => '0');
                udp_tx_hdr_dst_ip_addr <= (others => '0');
            when CMD => 
            when CMD_WAIT => 
            when DATA => 
            when DATA_WAIT => 
            when DATA_WAIT_DONE => 
            when DELAY => 
            when CPLT => 
            when ACK_SEQ => 
                udp_tx_hdr_dst_port <= ack_dst_port;
                udp_tx_hdr_src_port <= c_src_port;
                udp_tx_hdr_dst_ip_addr <= ack_dst_ip;
            when ACK_SEQ_WAIT => 
                udp_tx_hdr_dst_port <= ack_dst_port;
                udp_tx_hdr_src_port <= c_src_port;
                udp_tx_hdr_dst_ip_addr <= ack_dst_ip;
            when ACK_FT =>  
                udp_tx_hdr_dst_port <= ack_dst_port;
                udp_tx_hdr_src_port <= c_src_port;
                udp_tx_hdr_dst_ip_addr <= ack_dst_ip;
            when ACK_FT_WAIT => 
                udp_tx_hdr_dst_port <= ack_dst_port;
                udp_tx_hdr_src_port <= c_src_port;
                udp_tx_hdr_dst_ip_addr <= ack_dst_ip;
        end case;
    end process; -- p_udp_hdr_out

    -- Combinational logic
    -- -------------------------------------------------------------------------
    -- store internal signals
    data_size_int <= to_integer(unsigned(data_size));
    -- calculate number of sequences to send
    -- ceiled division by c_nbytes_per_packet
    cmd_nseq <= std_logic_vector( to_unsigned(to_integer(unsigned(data_size)) / c_nbytes_per_packet, cmd_nseq'length) )
        when data_size(1 downto 0) = "00" else
        std_logic_vector( to_unsigned(to_integer(unsigned(data_size)) / c_nbytes_per_packet, cmd_nseq'length) + 1);
    --cmd_nseq <= std_logic_vector(shift_right(unsigned(data_size), 10) + 1);

    cmd_seqnbr  <= ack_seqnbr;
    
    -- data pointer offset by data_src_addr and number of sequence number 
    -- times the maximum number of bytes per data packet
    data_data_src_addr <= std_logic_vector(data_offset + unsigned(data_src_addr));
    
    -- output current sequence number
    data_seq <= std_logic_vector(nseq_ctr);


    ----------------------------------------------------------------------------
    -- packet data size is either data size remainder or maximum
    -- -------------------------------------------------------------------------
    p_packet_data_size_calc : process( current_state, remaining_bytes )
    ----------------------------------------------------------------------------
    begin
        if remaining_bytes > c_nbytes_per_packet then
            packet_data_size_int <= std_logic_vector(to_unsigned(c_nbytes_per_packet, packet_data_size_int'length));
        else
            packet_data_size_int <= std_logic_vector(remaining_bytes(10 downto 0));
        end if;
    end process ; -- p_packet_data_size_calc
    packet_data_size  <=  packet_data_size_int;

end architecture structural;