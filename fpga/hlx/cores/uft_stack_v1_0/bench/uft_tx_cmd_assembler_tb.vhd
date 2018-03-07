-------------------------------------------------------------------------------
-- Title       : UFT TX Command Packet generator test bench
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_tx_cmd_assembler_tb.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Tue Nov 28 13:44:06 2017
-- Last update : Tue Nov 28 14:28:53 2017
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

entity uft_tx_cmd_assembler_tb is

end entity uft_tx_cmd_assembler_tb;

-----------------------------------------------------------

architecture testbench of uft_tx_cmd_assembler_tb is

    -- Testbench signals
    signal clk       : std_logic;
    signal rst_n     : std_logic;
    signal data_size : std_logic_vector (31 downto 0);
    signal tcid      : std_logic_vector (6 downto 0);
    signal en_start  : std_logic;
    signal done      : std_logic;
    signal tx_tvalid : std_logic;
    signal tx_tlast  : std_logic;
    signal tx_tdata  : std_logic_vector (7 downto 0);
    signal tx_tready : std_logic;

    constant C_CLK_PERIOD : time := 8.0 ns; -- NS
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
                 '1' after 20.0*C_CLK_PERIOD;
        wait;
    end process RESET_GEN;

    -----------------------------------------------------------
    -- Testbench Stimulus
    -----------------------------------------------------------
    p_sim : process
    begin
        data_size <= std_logic_vector(to_unsigned(100, data_size'length));
        tcid <= std_logic_vector(to_unsigned(0, tcid'length));
        en_start <= '0';
        tx_tready <= '0';

        wait for 25*C_CLK_PERIOD;

        ------------------------------------------------------------------------
        -- TEST 1: 100 byte data transfer
        -- ---------------------------------------------------------------------
        report "-- TEST 1: 100 byte data transfer";
        en_start <= '1';
        data_size <= std_logic_vector(to_unsigned(100, data_size'length));
        tcid <= std_logic_vector(to_unsigned(0, tcid'length));
        tx_tready <= '1';
        wait for 1*C_CLK_PERIOD;        
        en_start <= '0';
        wait until done = '1';
        tx_tready <= '0';
        wait for 3*C_CLK_PERIOD;

        ------------------------------------------------------------------------
        -- TEST 2: 20 bytes with tvalid interrupt
        -- ---------------------------------------------------------------------
        report "-- TEST 2: 20 bytes with tvalid interrupt";
        en_start <= '1';
        data_size <= std_logic_vector(to_unsigned(20, data_size'length));
        tcid <= std_logic_vector(to_unsigned(0, tcid'length));
        tx_tready <= '1';
        wait for 1*C_CLK_PERIOD;        
        en_start <= '0';
        wait for 5*C_CLK_PERIOD; 
        tx_tready <= '0';
        wait for 1*C_CLK_PERIOD; 
        tx_tready <= '1';
        wait for 3*C_CLK_PERIOD; 
        tx_tready <= '0';
        wait for 10*C_CLK_PERIOD; 
        tx_tready <= '1';
        wait for 10*C_CLK_PERIOD; 
        tx_tready <= '0';
        wait for 1*C_CLK_PERIOD; 
        tx_tready <= '1';
        
        wait until done = '1';
        tx_tready <= '0';
        wait for 3*C_CLK_PERIOD;

        ------------------------------------------------------------------------
        -- TEST 3: 1024 byte data transfer
        -- ---------------------------------------------------------------------
        report "-- TEST 3: 1024 byte data transfer";
        en_start <= '1';
        data_size <= std_logic_vector(to_unsigned(1024, data_size'length));
        tcid <= std_logic_vector(to_unsigned(120, tcid'length));
        tx_tready <= '1';
        wait for 1*C_CLK_PERIOD;        
        en_start <= '0';
        wait until done = '1';
        tx_tready <= '0';
        wait for 3*C_CLK_PERIOD;


        stop_sim <= '1';
        wait;
    end process p_sim;

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    DUT : entity work.uft_tx_cmd_assembler
        port map (
            clk       => clk,
            rst_n     => rst_n,
            data_size => data_size,
            tcid      => tcid,
            en_start  => en_start,
            done      => done,
            tx_tvalid => tx_tvalid,
            tx_tlast  => tx_tlast,
            tx_tdata  => tx_tdata,
            tx_tready => tx_tready
        );

end architecture testbench;