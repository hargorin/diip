-------------------------------------------------------------------------------
-- Title       : Mean and Variance Testbench
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : mean_var_tb.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : User Company Name
-- Created     : Tue Jul 10 16:22:03 2018
-- Last update : Tue Jul 10 16:28:12 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 User Company Name
-------------------------------------------------------------------------------
-- Description: Testbench to calculate the mean and variance
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

entity mean_var_tb is

end entity mean_var_tb;

-----------------------------------------------------------

architecture testbench of mean_var_tb is

	-- Testbench DUT generics as constants
    constant WIN_LENGTH : positive := 21;
    constant WIN_SIZE   : positive := (WIN_LENGTH * WIN_LENGTH);
    constant WIN_DEN    : positive := (1/WIN_SIZE);

	-- Testbench DUT ports as signals
    signal clk     : std_logic;
    signal rst_n   : std_logic;
    signal inData  : std_logic_vector(7 downto 0);
    signal outMean : std_logic_vector(7 downto 0);
    signal outVar  : std_logic_vector(13 downto 0);
    signal valid   : std_logic;
    signal en       : std_logic := '0';
    signal clear    : std_logic := '0';

	-- Other constants
    constant clk_period : time := 10 ns;
    signal stop_sim  : std_logic := '0';

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
    CLK_GEN : process
    begin
        clk <= '1';
        wait for clk_period / 2.0;
        clk <= '0';
        wait for clk_period / 2.0;

        if stop_sim = '1' then
            wait;
        end if;
    end process CLK_GEN;

    RESET_GEN : process
    begin
        rst_n <= '0',
                 '1' after 20.0*clk_period;
        wait;
    end process RESET_GEN;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------
	p_sim : process
        procedure waitfor ( t : in natural ) is
        begin
            wait for t*clk_period;
            wait until rising_edge(clk);
        end procedure waitfor;

	begin
		waitfor(25);

		waitfor(5);
        stop_sim <= '1';
        wait;
	end process; -- p_sim
	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    DUT : entity work.mean_var
        generic map (
            WIN_LENGTH => WIN_LENGTH,
            WIN_SIZE   => WIN_SIZE,
            WIN_DEN    => WIN_DEN
        )
        port map (
            clk     => clk,
            rst_n   => rst_n,
            inData  => inData,
            outMean => outMean,
            outVar  => outVar,
            valid   => valid,
            en      => en,
            clear   => clear
        );

end architecture testbench;