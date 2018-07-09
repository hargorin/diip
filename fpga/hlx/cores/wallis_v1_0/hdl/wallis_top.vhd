-------------------------------------------------------------------------------
-- Title       : UFT Top Module
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_top.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Nov 22 15:53:25 2017
-- Last update : Wed May  9 15:23:24 2018
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: UDP File Transfer top module, combines transmitter and receiver
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------


library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


entity wallis_top is
    --generic (

    --);
    port (
        -- clk and reset
        ------------------------------------------------------------------------
        clk     : in    std_logic;
        rst_n   : in    std_logic

    );
end entity wallis_top;

architecture structural of wallis_top is

begin
  

end architecture structural;
