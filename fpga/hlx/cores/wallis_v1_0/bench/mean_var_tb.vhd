-------------------------------------------------------------------------------
-- Title       : Mean and Variance Testbench
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : mean_var_tb.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : User Company Name
-- Created     : Tue Jul 10 16:22:03 2018
-- Last update : Thu Jul 12 16:58:23 2018
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
    constant delay       : positive                  := 21*21;
    constant M_IN_WIDTH  : positive                  := 8;
    constant M_OUT_WIDTH : positive                  := 17;
    constant V_IN_WIDTH  : positive                  := 16;
    constant V_OUT_WIDTH : positive                  := 25;
    constant ACCURACY    : positive                  := 15;
    constant WIN_DEN	 : unsigned(6 downto 0)      := to_unsigned(74, 7);

	-- Testbench DUT ports as signals
    signal clk     : std_logic;
    signal rst_n   : std_logic;
    signal inData  : std_logic_vector(7 downto 0);
    signal outMean : std_logic_vector(7 downto 0);
    signal outVar  : std_logic_vector(13 downto 0);
    signal en      : std_logic :='0';
    signal clear   : std_logic :='0';

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
		en <= '1';
		inData <= x"FF";
		waitfor(500);
		en <= '0';
		assert (outMean = x"FF") report "Mean is not 2" severity error;

		waitfor(5);
        stop_sim <= '1';
        wait;
	end process; -- p_sim
	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    DUT : entity work.mean_var
        generic map (
            delay       => delay,
            M_IN_WIDTH  => M_IN_WIDTH,
            M_OUT_WIDTH => M_OUT_WIDTH,
            V_IN_WIDTH  => V_IN_WIDTH,
            V_OUT_WIDTH => V_OUT_WIDTH,
            ACCURACY    => ACCURACY,
            WIN_DEN     => WIN_DEN
        )
        port map (
            clk     => clk,
            rst_n   => rst_n,
            inData  => inData,
            outMean => outMean,
            outVar  => outVar,
            en      => en,
            clear   => clear
        );

end architecture testbench;