-------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : template_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Mon Jul 16 13:31:02 2018
-- Last update : Wed Jul 18 14:09:21 2018
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

entity template_tb is

end entity template_tb;

-----------------------------------------------------------

architecture testbench of template_tb is

	-- Testbench DUT generics as constants

	-- Testbench DUT ports as signals

	-- Other constants
    constant clk_period : time := 8 ns;
	signal stop_sim : std_logic := '0';

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
                 '1' after 5.0*clk_period;
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
        waitfor(10);

        -- start stim
        

    	stop_sim <= '1';
    end process;


	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
    
end architecture testbench;