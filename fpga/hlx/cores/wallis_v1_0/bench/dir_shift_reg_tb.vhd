-------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Wallis Filter
-------------------------------------------------------------------------------
-- File        : dir_shift_reg_tb.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : FHNW
-- Created     : Tue Jul 10 12:39:33 2018
-- Last update : Mon Jul 23 11:13:23 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 FHNW
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

entity dir_shift_reg_tb is

end entity dir_shift_reg_tb;

-----------------------------------------------------------

architecture testbench of dir_shift_reg_tb is

	-- Testbench DUT generics as constants
    constant WIN_SIZE    : positive := 4;
	constant DATA_WIDTH  : positive := 8;
    constant FIFO_DEPTH  : positive := WIN_SIZE + 3;

	-- Testbench DUT ports as signals
    signal clk      : std_logic;
    signal rst_n    : std_logic;
    signal datain   : std_logic_vector(7 downto 0);
    signal dataoutp : std_logic_vector(7 downto 0);
    signal dataoutm : std_logic_vector(7 downto 0);
    signal valid    : std_logic;
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
		datain <= x"00";
		waitfor(25);


		-------------------
		-- Shift Register Test
		-------------------
		en  <= '1';
		datain  <= x"01";
		waitfor(1);
		datain  <= x"02";
		waitfor(1);
		datain  <= x"03";
		waitfor(1);
		datain  <= x"04";
		waitfor(1);
		datain  <= x"05";
		waitfor(1);
		datain  <= x"06";
		waitfor(1);
		datain  <= x"07";
		waitfor(1);
		en  <= '0';
		waitfor(4);

		en  <= '1';
		waitfor(3);
		en  <= '0';

		-------------------
		-- Clear
		-------------------
    	clear <= '1';
    	waitfor(1);
    	clear <= '0';
    	waitfor(1);

		-------------------
		-- Shift Register Test
		-------------------
		datain  <= x"01";
		waitfor(1);
		datain  <= x"02";
		waitfor(1);
		datain  <= x"03";
		waitfor(1);
		datain  <= x"04";
		waitfor(1);

		en  <= '1';
		datain  <= x"05";
		waitfor(1);
		datain  <= x"06";
		waitfor(1);
		datain  <= x"07";
		waitfor(3);
		en  <= '0';
		waitfor(3);
		

		waitfor(5);
        stop_sim <= '1';
        wait;
	end process; -- p_sim

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    DUT : entity work.dir_shift_reg
        generic map (
            WIN_SIZE => WIN_SIZE
        )
        port map (
            clk      => clk,
            rst_n    => rst_n,
            datain   => datain,
            dataoutp => dataoutp,
            dataoutm => dataoutm,
            valid    => valid,
            en       => en,
            clear    => clear
        );

end architecture testbench;