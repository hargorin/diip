-------------------------------------------------------------------------------
-- Title       : Impulse Generator TB
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : impulse_generator_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Thu Nov 30 09:22:01 2017
-- Last update : Tue Jul 10 08:35:23 2018
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

entity impulse_generator_tb is

end entity impulse_generator_tb;

-----------------------------------------------------------

architecture testbench of impulse_generator_tb is

    -- Testbench signals
    signal clk     : std_logic;
    signal rst     : std_logic;
    signal enable   : std_logic := '0';
    signal impulse : std_logic;

    constant C_CLK_PERIOD : time := 10 ns; -- NS
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
        rst <= '1';
        waitfor(3);
        rst <= '0';

        waitfor(3);
        enable <= '1';
        waitfor(2);
        assert (impulse = '1') report "Impulse not occured" severity error;
        waitfor(3);
        assert (impulse = '0') report "Impulse not reset" severity error;
        enable <= '0';

        waitfor(5);
        enable <= '1';
        waitfor(1);
        enable <= '0';
        waitfor(1);
        assert (impulse = '1') report "Impulse not occured" severity error;
        waitfor(3);
        assert (impulse = '0') report "Impulse not reset" severity error;
        waitfor(5);

        assert false report "All test successful" severity note;
        stop_sim <= '1';
        wait;
    end process ; -- p_sim

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    DUT : entity work.impulse_generator
        generic map (
            C_IMPULSE_DURATION => 2
        )
        port map (
            clk     => clk,
            rst     => rst,
            enable   => enable,
            impulse => impulse
        );

end architecture testbench;