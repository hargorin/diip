-------------------------------------------------------------------------------
-- Title       : UDP File Transfer receiver
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_rx.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.ocom>
-- Company     : User Company Name
-- Created     : Wed Nov  8 11:19:21 2017
-- Last update : Fri Apr 20 13:01:49 2018
-- Platform    : Default Part Number
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Description: decrypts the UFT protocol header
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity uft_rx is
    generic (
        -- only treat packages arriving at INCOMMING_PORT as UFT packages
        INCOMMING_PORT : natural := 42042
    );
    port (
        -- clk and reset
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- Connection to UDP Stack
        udp_rx_start        : in std_logic;
        --udp_rxo             : in udp_rx_type;
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

        -- Outputs
        is_command              : out std_logic;
        command_code            : out std_logic_vector(6 downto 0);
        command_data1           : out std_logic_vector(23 downto 0);
        command_data2           : out std_logic_vector(31 downto 0);
        command_data_valid      : out std_logic;
        
        is_data                 : out std_logic;
        data_tcid               : out std_logic_vector( 6 downto 0);
        data_seq                : out std_logic_vector(23 downto 0);
        data_meta_valid         : out std_logic;
        data_tvalid             : out std_logic;
        data_tlast              : out std_logic;
        data_tdata              : out std_logic_vector( 7 downto 0);

        src_ip      : out std_logic_vector (31 downto 0);
        src_port    : out std_logic_vector (15 downto 0)
    );
end entity uft_rx;

architecture rtl of uft_rx is

    -- type defs
    type state_type is ( IDLE, RX_START,
        CMD1_2, CMD1_1, CMD1_0, CMD2_3, CMD2_2, CMD2_1, CMD2_0, RX_CMD_COMPLETE,
        DATA_SEQ2, DATA_SEQ1, DATA_SEQ0, PAYLOAD, PAYLOAD_LAST, RX_DATA_COMPLETE );

    -- signals
    signal current_state    : state_type;
    signal next_state       : state_type;

    signal data_in : std_logic_vector(7 downto 0);

begin
    ----------------------------------------------------------------------------
    p_state_proc_clocked : process( clk )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                current_state <= IDLE;
            else
                current_state <= next_state;
            end if;
        end if;
    end process ; -- p_state_proc_clocked

    ----------------------------------------------------------------------------
    p_data_in_buf : process( clk )
    ----------------------------------------------------------------------------
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                data_in <= x"00";
            else
                if (udp_rx_tvalid = '1') then
                    data_in <= udp_rx_tdata;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    p_next_state : process ( udp_rx_start, udp_rx_hdr_is_valid, clk, data_in, 
        current_state, udp_rx_hdr_dst_port, udp_rx_tvalid )
    ----------------------------------------------------------------------------
    begin
        case (current_state) is
            when IDLE =>
                if (udp_rx_start = '1') AND ( (udp_rx_hdr_is_valid = '1') AND (udp_rx_hdr_dst_port = std_logic_vector(to_unsigned(INCOMMING_PORT,16)) ) ) then
                    next_state <= RX_START;
                else
                    next_state <= current_state;
                end if;
            when RX_START =>
                if ( udp_rx_tvalid = '1' ) AND (data_in(7) = '0' ) then
                    next_state <= CMD1_2;
                elsif ( udp_rx_tvalid = '1' ) AND (data_in(7) = '1' ) then
                    next_state <= DATA_SEQ2;
                else
                    next_state <= current_state;
                end if;
            when CMD1_2 =>
                if ( udp_rx_tvalid = '1' ) then
                    next_state <= CMD1_1;
                else
                    next_state <= current_state;
                end if;
            when CMD1_1 =>
                if ( udp_rx_tvalid = '1' ) then
                    next_state <= CMD1_0;
                else
                    next_state <= current_state;
                end if;
            when CMD1_0 =>
                if ( udp_rx_tvalid = '1' ) then
                    next_state <= CMD2_3;
                else
                    next_state <= current_state;
                end if;
            when CMD2_3 =>
                if ( udp_rx_tvalid = '1' ) then
                    next_state <= CMD2_2;
                else
                    next_state <= current_state;
                end if;
            when CMD2_2 =>
                if ( udp_rx_tvalid = '1' ) then
                    next_state <= CMD2_1;
                else
                    next_state <= current_state;
                end if;
            when CMD2_1 =>
                if ( udp_rx_tvalid = '1' ) then
                    next_state <= CMD2_0;
                else
                    next_state <= current_state;
                end if;
            when CMD2_0 =>
                if ( udp_rx_tvalid = '1' ) then
                    next_state <= RX_CMD_COMPLETE;
                else
                    next_state <= current_state;
                end if;
            when RX_CMD_COMPLETE =>
                if ( udp_rx_start = '0' ) then
                    next_state <= IDLE;
                else
                    next_state <= current_state;
                end if;
            when DATA_SEQ2 =>
                if ( udp_rx_tvalid = '1' ) then
                    next_state <= DATA_SEQ1;
                else
                    next_state <= current_state;
                end if;
            when DATA_SEQ1 =>
                if ( udp_rx_tvalid = '1' ) then
                    next_state <= DATA_SEQ0;
                else
                    next_state <= current_state;
                end if;
            when DATA_SEQ0 =>
                if ( udp_rx_tvalid = '1' ) then
                    next_state <= PAYLOAD;
                else
                    next_state <= current_state;
                end if;
            when PAYLOAD =>
                if ( udp_rx_tlast = '1' ) then
                    next_state <= PAYLOAD_LAST;
                else
                    next_state <= current_state;
                end if;
            when PAYLOAD_LAST =>
                    next_state <= RX_DATA_COMPLETE;
            when RX_DATA_COMPLETE =>
                if (udp_rx_start = '0') then
                    next_state <= IDLE;
                else
                    next_state <= current_state;
                end if;
        end case;
    end process p_next_state;

    p_output_latched : process( clk )
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                command_data1 <= (others  => '0');
                command_data2 <= (others  => '0');
                command_code <= (others  => '0');
                data_seq <= (others  => '0');
                data_tcid <= (others  => '0');
                is_data <= '0';
                is_command <= '0';
            else
                case (current_state) is
                    when IDLE =>
                        is_command <= '0';
                        is_data <= '0';
                    when RX_START =>
                        if (data_in(7) = '0' ) then
                            is_command <= '1';
                            command_code <= data_in(6 downto 0);
                        elsif (data_in(7) = '1' ) then
                            is_data <= '1';
                            data_tcid <= data_in(6 downto 0);
                        end if;
                    when CMD1_2 =>
                        command_data1(23 downto 16) <= data_in;
                    when CMD1_1 =>
                        command_data1(15 downto 8) <= data_in;
                    when CMD1_0 =>
                        command_data1(7 downto 0) <= data_in;
                    when CMD2_3 =>
                        command_data2(31 downto 24) <= data_in;
                    when CMD2_2 =>
                        command_data2(23 downto 16) <= data_in;
                    when CMD2_1 =>
                        command_data2(15 downto 8) <= data_in;
                    when CMD2_0 =>
                        command_data2(7 downto 0) <= data_in;
                    when RX_CMD_COMPLETE =>
                        
                    when DATA_SEQ2 =>
                        src_ip <= udp_rx_hdr_src_ip_addr;
                        src_port <= udp_rx_hdr_src_port;
                        data_seq(23 downto 16)  <= data_in;
                    when DATA_SEQ1 =>
                        data_seq(15 downto 8)  <= data_in;
                    when DATA_SEQ0 =>
                        data_seq(7 downto 0)  <= data_in;
                    when PAYLOAD =>
                        
                    when PAYLOAD_LAST =>
                        
                    when RX_DATA_COMPLETE =>
                        
                end case;
            end if;
        end if;
    end process ; -- p_output_latched

    ----------------------------------------------------------------------------
    -- Outputs
    ----------------------------------------------------------------------------
    --is_command  <=   '1'   when current_state = RX_CMD_COMPLETE else '0';
    --is_data     <=   '1'   when (current_state = PAYLOAD) OR (current_state = PAYLOAD_LAST) else '0';
    command_data_valid   <=   '1' when current_state = RX_CMD_COMPLETE else '0';
    data_meta_valid      <=   '1' when (current_state = PAYLOAD) OR (current_state = PAYLOAD_LAST) else '0';

    data_tvalid      <= '1' when ( (current_state = PAYLOAD) OR (current_state = PAYLOAD_LAST) ) else '0';
    data_tdata       <= data_in;
    data_tlast       <= '1' when current_state = PAYLOAD_LAST else '0';


end architecture rtl;