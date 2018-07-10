-------------------------------------------------------------------------------
-- Title       : Difference and Add
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : sum_diff.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : User Company Name
-- Created     : Wed Nov 22 15:53:25 2017
-- Last update : Tue Jul 10 12:34:48 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Calculate the difference from two inputs and sum them up
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------


library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


entity sum_diff is
    --generic (

    --);
    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- inputs
        ------------------------------------------------------------------------
        inp 	: in 	std_logic_vector(7 downto 0);
        inm 	: in 	std_logic_vector(7 downto 0);

        -- outputs
        ------------------------------------------------------------------------
        sum 	: out	std_logic_vector(17 downto 0);

        -- controls
        ------------------------------------------------------------------------
        en 		: in 	std_logic;
        clear	: in 	std_logic

    );
end entity sum_diff;

architecture rtl of sum_diff is

	signal difference : signed(9 downto 0);
	signal sumi : signed(17 downto 0);

	signal inpi : signed(9 downto 0);
	signal inmi : signed(9 downto 0);
begin

	inpi(7 downto 0) <= signed(inp);
	inpi(9 downto 8) <= (others => '0');
	inmi(7 downto 0) <= signed(inm);
	inmi(9 downto 8) <= (others => '0');

	difference <= inpi - inmi;
	sum <= std_logic_vector(sumi(17 downto 0));

	p_add : process(clk) is
	begin
		if rising_edge(clk) then
			if (rst_n = '0') then
				sumi <= (others  => '0');
			else
				if (clear = '1') then
					sumi <= (others  => '0');
				else	
					if (en = '1') then
						sumi <= sumi + difference;
					else 
						sumi <= sumi;
					end if;	
				end if;
			end if;
		end if;		
	end process; -- add
end architecture rtl;
