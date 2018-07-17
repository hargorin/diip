-------------------------------------------------------------------------------
-- Title       : Wallis Filter
-- Project     : Wallis Filter
-------------------------------------------------------------------------------
-- File        : wallis_filter.vhd
-- Author      : Jan Stocker (jan.stocker@students.fhnw.ch)
-- Company     : User Company Name
-- Created     : Tue Jul 17 09:19:14 2018
-- Last update : Tue Jul 17 09:25:33 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 FHNW
-------------------------------------------------------------------------------
-- Description: Wallis algorithm
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


entity wallis_filter is
    --generic (

    --);

    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic;

        -- inputs
        ------------------------------------------------------------------------
        pixel 	: in 	std_logic_vector(7 downto 0);
        n_mean	: in 	std_logic_vector(7 downto 0);
        n_var	: in 	std_logic_vector(13 downto 0);
        

        -- outputs
        ------------------------------------------------------------------------
        wallis 	: out	std_logic_vector(7 downto 0);

        -- controls
        ------------------------------------------------------------------------
        valid	: out	std_logic;
        en 		: in 	std_logic;
        clear	: in 	std_logic

    );
end entity wallis_filter;

architecture rtl of wallis_filter is

begin


end architecture rtl;
