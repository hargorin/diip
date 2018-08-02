-------------------------------------------------------------------------------
-- Title       : Comm Package
-- Project     : Default Project Name
-------------------------------------------------------------------------------
-- File        : uft_pkg.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Wed Nov 15 11:27:54 2017
-- Last update : Sat Dec  2 15:33:23 2017
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Copyright (c) 2017 User Company Name
-------------------------------------------------------------------------------
-- Description: Communication Package file
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;


package uft_pkg is
    -- set to true to use modules for simulation purposes
    constant c_pkg_simulation : boolean := false;

    -- UFT AXI parameters
    constant c_pkg_m_axi_addr_width  : integer := 32;
    constant c_pkg_uft_rx_base_addr : std_logic_vector(c_pkg_m_axi_addr_width-1 downto 0) := x"08000000";
    -- Size in bytes of the receiving UFT packet
    constant c_pkg_uft_rx_pack_size  : unsigned(c_pkg_m_axi_addr_width-1 downto 0) := to_unsigned(1024,c_pkg_m_axi_addr_width);
end package uft_pkg;
