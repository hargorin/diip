-------------------------------------------------------------------------------
-- Title       : UFT TX Control TB
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_tx_control_tb.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Wed Nov 29 15:20:24 2017
-- Last update : Fri Mar  9 11:04:16 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: TB
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

-----------------------------------------------------------

entity uft_tx_control_tb is
    generic (
        C_M_AXI_ADDR_WIDTH  : integer range 32 to 64  := 32
    );
end entity uft_tx_control_tb;

-----------------------------------------------------------

architecture testbench of uft_tx_control_tb is

    -- Testbench signals
    signal clk                : std_logic;
    signal rst_n              : std_logic;
    signal data_size          : std_logic_vector(31 downto 0);
    signal data_src_addr      : std_logic_vector (C_M_AXI_ADDR_WIDTH-1 downto 0);
    signal tx_ready           : std_logic;
    signal tx_start           : std_logic;
    signal udp_tx_start                : std_logic;
    signal udp_tx_result               :  std_logic_vector (1 downto 0);
    signal udp_tx_hdr_data_length      : std_logic_vector (15 downto 0);
    signal udp_tx_hdr_checksum         : std_logic_vector (15 downto 0);
    signal arb_sel            : std_logic;
    signal cmd_tcid           : std_logic_vector (6 downto 0);
    signal cmd_en_start       : std_logic;
    signal cmd_done           : std_logic;
    signal cmd_nseq           : std_logic_vector (31 downto 0);
    signal data_data_src_addr : std_logic_vector (C_M_AXI_ADDR_WIDTH-1 downto 0);
    signal data_tcid          : std_logic_vector (6 downto 0);
    signal data_seq           : std_logic_vector (23 downto 0);
    signal packet_data_size   : std_logic_vector (10 downto 0);
    signal data_start         : std_logic;
    signal data_done          : std_logic;

    constant C_CLK_PERIOD : time := 8 ns; -- NS
    signal stop_sim : std_logic := '0';

begin
    -----------------------------------------------------------
    -- Clocks and Reset
    -----------------------------------------------------------
    CLK_GEN : process
    begin
        clk <= '1';
        wait for C_CLK_PERIOD / 2.0;
        clk <= '0';
        wait for C_CLK_PERIOD / 2.0;

        if stop_sim = '1' then
            wait;
        end if;
    end process CLK_GEN;

    RESET_GEN : process
    begin
        rst_n <= '0',
                 '1' after 5.0*C_CLK_PERIOD;
        wait;
    end process RESET_GEN;

    -----------------------------------------------------------
    -- Testbench Stimulus
    -----------------------------------------------------------
    p_sim : process
        procedure waitfor ( t : in natural ) is
        begin
            wait for t*C_CLK_PERIOD;
            wait until rising_edge(clk);
        end procedure waitfor;
    begin
        data_size <= (others => '0');
        data_src_addr <= (others => '0');
        tx_start <= '0';
        cmd_done <= '0';
        data_done <= '0';
        waitfor(7);

        ------------------------------------------------------------------------
        -- TEST 1: Send 100 bytes
        -- ---------------------------------------------------------------------
        report "-- TEST 1: Send 100 bytes";
        data_size <=std_logic_vector(to_unsigned(100, data_size'length));
        data_src_addr <= std_logic_vector(to_unsigned(0, data_src_addr'length));
        tx_start <= '1';
        cmd_done <= '0';
        data_done <= '0';
        waitfor(1);
        tx_start <= '0';
        waitfor(5);
        cmd_done <= '1';
        waitfor(1);
        cmd_done <= '0';
        waitfor(5);
        data_done <= '1';
        waitfor(1);
        data_done <= '0';
        wait until tx_ready = '1';
        waitfor(10);

        ------------------------------------------------------------------------
        -- TEST 2: Send 2000 bytes
        -- ---------------------------------------------------------------------
        report "-- TEST 2: Send 2000 bytes";
        data_size <=std_logic_vector(to_unsigned(2000, data_size'length));
        data_src_addr <= std_logic_vector(to_unsigned(0, data_src_addr'length));
        tx_start <= '1';
        cmd_done <= '0';
        data_done <= '0';
        waitfor(1);
        tx_start <= '0';
        waitfor(5);

        cmd_done <= '1';
        waitfor(1);
        cmd_done <= '0';

        -- 2000 bytes will be split into 2 data packets
        for i in 1 to 2 loop
            wait until data_start = '1';
            waitfor(5);
            data_done <= '1';
            waitfor(1);
            data_done <= '0';
        end loop;

        wait until tx_ready = '1';
        waitfor(10);

        ------------------------------------------------------------------------
        -- TEST 3: Send 10'000 bytes
        -- ---------------------------------------------------------------------
        report "-- TEST 3: Send 10'000 bytes";
        data_size <=std_logic_vector(to_unsigned(10000, data_size'length));
        data_src_addr <= std_logic_vector(to_unsigned(0, data_src_addr'length));
        tx_start <= '1';
        cmd_done <= '0';
        data_done <= '0';
        waitfor(1);
        tx_start <= '0';
        waitfor(5);

        cmd_done <= '1';
        waitfor(1);
        cmd_done <= '0';

        -- 10'000 bytes will be split into 10 data packets
        for i in 1 to 10 loop
            wait until data_start = '1';
            waitfor(5);
            data_done <= '1';
            waitfor(1);
            data_done <= '0';
        end loop;


        waitfor(3);
        stop_sim <= '1';
        wait;
    end process p_sim;

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    DUT : entity work.uft_tx_control
        generic map (
            C_M_AXI_ADDR_WIDTH => C_M_AXI_ADDR_WIDTH,
            C_PACKET_DELAY_US => 1
        )
        port map (
            clk                    => clk,
            rst_n                  => rst_n,
            data_size              => data_size,
            data_src_addr          => data_src_addr,
            tx_ready               => tx_ready,
            tx_start               => tx_start,
            udp_tx_start           => udp_tx_start,
            udp_tx_result          => udp_tx_result,
            udp_tx_hdr_data_length => udp_tx_hdr_data_length,
            udp_tx_hdr_checksum    => udp_tx_hdr_checksum,
            arb_sel                => arb_sel,
            cmd_tcid               => cmd_tcid,
            cmd_en_start           => cmd_en_start,
            cmd_done               => cmd_done,
            cmd_nseq               => cmd_nseq,
            data_data_src_addr     => data_data_src_addr,
            data_tcid              => data_tcid,
            data_seq               => data_seq,
            packet_data_size       => packet_data_size,
            data_start             => data_start,
            data_done              => data_done
        );        

end architecture testbench;