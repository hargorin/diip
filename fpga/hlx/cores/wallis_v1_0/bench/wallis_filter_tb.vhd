-------------------------------------------------------------------------------
-- Title       : Wallis Filter Testbench
-- Project     : Wallis Filter
-------------------------------------------------------------------------------
-- File        : wallis_filter_tb.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : User Company Name
-- Created     : Wed Jul 18 09:16:39 2018
-- Last update : Wed Jul 18 12:12:03 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 2018 FHNW
-------------------------------------------------------------------------------
-- Description: Testbench for the Wallis algorithm
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

entity wallis_filter_tb is

end entity wallis_filter_tb;

-----------------------------------------------------------

architecture testbench of wallis_filter_tb is

	-- Testbench DUT generics as constants
    constant ONE : unsigned(5 downto 0) := "111111";

	-- Testbench DUT ports as signals
    signal clk        	: std_logic;
    signal rst_n      	: std_logic;
    signal pixel      	: std_logic_vector(7 downto 0);
    signal n_mean     	: std_logic_vector(7 downto 0);
    signal n_var      	: std_logic_vector(13 downto 0);
   	signal par_c_gvar	: std_logic_vector(19 downto 0) := "00101101101101000000"; --2925
   	signal par_ci_gvar	: std_logic_vector(19 downto 0) := "00001010100011000000"; --675
   	signal par_c 		: std_logic_vector(5 downto 0) := "110100"; --0.8125
   	signal par_b_gmean 	: std_logic_vector(13 downto 0) := "00111101100001"; --61.515625
   	signal par_bi		: std_logic_vector(5 downto 0) := "100001"; --0.515625
    signal wallis     	: std_logic_vector(7 downto 0);
    signal valid      	: std_logic;
    signal en         	: std_logic;
    signal clear      	: std_logic;

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
    	pixel <= x"FF"; --255
    	n_mean <= x"64"; --100
    	n_var <= "00000000001010"; --10
  	
    	waitfor(1);
    	pixel <= x"0A"; --10
    	n_mean <= x"FF"; --255
    	n_var <= "00101110111000"; --3000

    	waitfor(1);
    	en <= '0';


		waitfor(3);
        stop_sim <= '1';
        wait;
	end process; -- p_sim

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    DUT : entity work.wallis_filter
        port map (
            clk         => clk,
            rst_n       => rst_n,
            pixel       => pixel,
            n_mean      => n_mean,
            n_var       => n_var,
            par_c_gvar  => par_c_gvar,
            par_ci_gvar => par_ci_gvar,
            par_c       => par_c,
            par_b_gmean => par_b_gmean,
            par_bi      => par_bi,
            wallis      => wallis,
            valid       => valid,
            en          => en,
            clear       => clear
        );
end architecture testbench;