-------------------------------------------------------------------------------
-- Title       : Debounce testbench
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : debounce_tb.vhd
-- Author      : Noah Huetter <noahhuetter@gmail.com>
-- Company     : User Company Name
-- Created     : Thu Nov 30 09:41:26 2017
-- Last update : Thu Nov 30 09:45:36 2017
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: 
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

entity debounce_tb is

end entity debounce_tb;

-----------------------------------------------------------

architecture testbench of debounce_tb is

    -- Testbench signals
    signal clk    : std_logic;
    signal button : std_logic;
    signal result : std_logic;

    constant C_CLK_PERIOD : time := 8 ns; -- NS
    signal stop_sim  : std_logic := '0';

begin
    -----------------------------------------------------------
    -- Clocks and Reset
    -----------------------------------------------------------
    CLK_GEN : process
    begin
        clk <= '1';
        wait for C_CLK_PERIOD / 2;
        clk <= '0';
        wait for C_CLK_PERIOD / 2;

        if stop_sim = '1' then
            wait;
        end if;
    end process CLK_GEN;

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
        waitfor(3);
        button <= '1';
        waitfor(5);
        button <= '0';
        
        waitfor(5);
        button <= '1';
        waitfor(1);
        button <= '0';
        waitfor(5);
        
        waitfor(5);
        button <= '1';
        wait for 20 ms;
        button <= '0';
        waitfor(5);

        stop_sim <= '1';
        wait;
    end process ; -- p_sim

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    DUT : entity work.debounce
        generic map (
            C_COUNTER_SIZE => 21
        )
        port map (
            clk    => clk,
            button => button,
            result => result
        );

end architecture testbench;