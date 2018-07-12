-------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : sum_diff_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Mon Jul  9 14:35:47 2018
-- Last update : Thu Jul 12 09:14:21 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 User Company Name
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

entity sum_diff_tb is

end entity sum_diff_tb;

-----------------------------------------------------------

architecture testbench of sum_diff_tb is

	-- Testbench DUT generics as constants
	constant IN_WIDTH : positive := 8;
	constant OUT_WIDTH : positive := 17;

	-- Testbench DUT ports as signals
    signal clk   : std_logic;
    signal rst_n : std_logic;
    signal inp   : std_logic_vector(IN_WIDTH - 1 downto 0) := (others => '0');
    signal inm   : std_logic_vector(IN_WIDTH - 1 downto 0) := (others => '0');
    signal sum   : std_logic_vector(OUT_WIDTH - 1 downto 0);
    signal en    : std_logic := '0';
    signal clear : std_logic := '0';

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

  		-- Count 2
    	en <= '1';
    	waitfor(2);
    	inp <= "00000010";
    	inm <= "00000001";
    	waitfor(2);
    	en <= '0';
    	inp <= "00000000";
    	inm <= "00000000";

    	waitfor(1);
    	assert (sum = "00000000000000010") report "Sum is not 2" severity error;
    	waitfor(1);

    	-- Clear
    	clear <= '1';
    	waitfor(3);
    	assert (sum = "00000000000000000") report "Sum is not 0" severity error;
    	waitfor(3);
    	clear <= '0';
    	waitfor(5);

  		-- Count 441 (Max)
    	en <= '1';
    	waitfor(2);
    	inp <= "11111111";
    	inm <= "00000000";
    	waitfor(441);
    	en <= '0';
    	inp <= "00000000";
    	inm <= "00000000";

    	waitfor(1);
    	assert (sum = "11011011101000111") report "Sum is not 112455" severity error;
    	waitfor(1);

    	-- Clear
    	clear <= '1';
    	waitfor(3);
    	assert (sum = "00000000000000000") report "Sum is not 0" severity error;
    	waitfor(3);
    	clear <= '0';
    	waitfor(1);

    	-- Count Plus and Minus
    	en <= '1';
    	waitfor(1);
    	inp <= "11111111";
    	inm <= "00000000";
    	waitfor(2);
    	inp <= "00000000";
    	inm <= "00001010";
    	waitfor(10);
    	en <= '0';

    	waitfor(1);
    	assert (sum = "00000000110011010") report "Sum is not 410" severity error;
    	waitfor(1);

 
        stop_sim <= '1';
        wait;
    end process p_sim;


	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    DUT : entity work.sum_diff
	    generic map (
	    	IN_WIDTH  => IN_WIDTH,
	    	OUT_WIDTH  => OUT_WIDTH
	    )
        port map (
            clk   => clk,
            rst_n => rst_n,
            inp   => inp,
            inm   => inm,
            sum   => sum,
            en    => en,
            clear => clear
        );

end architecture testbench;